"""Testes de stress da busca 1:N com pgvector (item 4.2 do backlog self-hosted).

Mede latência e qualidade da mesma query que `identify_biometric`
(app/routers/biometric.py) emite, com volumes de 10k/100k/1M templates
sintéticos, comparando busca exacta (sequential scan) com o índice HNSW criado
pela migration `76692ef15c1a`.

## Como correr

Precisa de um PostgreSQL **descartável** com a extensão pgvector:

    docker run -d --name pgvector-stress -e POSTGRES_PASSWORD=stress \\
        -p 55432:5432 postgres16-pgvector:0.8.1

    STRESS_DATABASE_URL=postgresql://postgres:stress@127.0.0.1:55432/postgres \\
        pytest tests/test_stress_identify_1n.py -s

Sem `STRESS_DATABASE_URL` os testes são ignorados, por isso a suite normal
(SQLite, ver conftest.py) não é afectada.

## Porque é que não usa a tabela `face_templates` real

O benchmark cria e destrói a sua própria tabela (`stress_face_templates`), com
as mesmas colunas relevantes e o mesmo índice HNSW. Assim é impossível
escrever centenas de milhares de linhas sintéticas numa base com dados
biométricos reais, mesmo que `STRESS_DATABASE_URL` seja apontado por engano
para um ambiente com dados. O que se mede — o comportamento do pgvector/HNSW
para esta forma de query — não depende de ser a tabela real.

## Como são gerados os dados (e porque é que isso importa)

Cada template é um vector unitário aleatório de 512 dimensões (uma "pessoa").
As *probes* **não** são vectores aleatórios: são uma versão com ruído de um
template já inserido, calibrada para uma similaridade cosseno de ~0.85 — a
gama em que caem duas capturas da mesma pessoa com o facenet.

Isto é essencial. Uma primeira versão deste benchmark usava probes aleatórias
e media recall por ID; em 512 dimensões vectores aleatórios são quase
equidistantes uns dos outros (concentração de distâncias), por isso o "top-5
verdadeiro" era um empate arbitrário e a recall medida (~0.29) não dizia nada
sobre a qualidade do índice. Com probes derivadas de uma linha real existe um
vizinho inequivocamente mais próximo, e a recall passa a medir aquilo que
interessa em produção: *o identify encontra a pessoa certa?*

## Variáveis de ambiente

- `STRESS_DATABASE_URL` — DSN do Postgres descartável (obrigatória).
- `STRESS_TEMPLATE_COUNTS` — volumes a testar, separados por vírgula.
  Por omissão `10000,100000`. O caso de 1M do backlog corre com
  `STRESS_TEMPLATE_COUNTS=1000000` (precisa de ~2 GB de disco e dezenas de
  minutos só a construir o índice).
- `STRESS_TENANTS` — número de tenants distintos a distribuir pelas linhas.
  Por omissão `1,50`.
- `STRESS_QUERIES` — número de queries por medição (omissão: 50).
"""

import json
import math
import os
import random
import statistics
import time

import pytest

psycopg2 = pytest.importorskip("psycopg2", reason="psycopg2 necessário para os testes de stress")
from psycopg2.extras import execute_batch  # noqa: E402

STRESS_DSN = os.getenv("STRESS_DATABASE_URL", "")

pytestmark = pytest.mark.skipif(
    not STRESS_DSN,
    reason="Defina STRESS_DATABASE_URL (Postgres descartável com pgvector) para correr os testes de stress.",
)

TABLE = "stress_face_templates"
INDEX = "ix_stress_face_templates_hnsw"
DIM = 512  # tem de coincidir com Vector(512) em app/models.py
MODEL_VERSION = "stress-model-v1"
TRANSFORM_VERSION = "stress-transform-v1"
TOP_K = 5

# Parâmetros do índice — iguais aos da migration 76692ef15c1a.
HNSW_M = 16
HNSW_EF_CONSTRUCTION = 64

# Desvio-padrão do ruído aplicado a um template para gerar a probe da mesma
# "pessoa". Para vectores unitários em DIM dimensões, a similaridade cosseno
# esperada é 1/sqrt(1 + DIM*sigma^2); sigma=0.027 dá ~0.85 em 512 dimensões,
# a gama típica de duas capturas da mesma pessoa com o facenet.
PROBE_NOISE_SIGMA = 0.027


def _counts() -> list[int]:
    raw = os.getenv("STRESS_TEMPLATE_COUNTS", "10000,100000")
    return [int(part.strip()) for part in raw.split(",") if part.strip()]


def _tenant_counts() -> list[int]:
    raw = os.getenv("STRESS_TENANTS", "1,50")
    return [int(part.strip()) for part in raw.split(",") if part.strip()]


def _n_queries() -> int:
    return int(os.getenv("STRESS_QUERIES", "50"))


def _random_unit_vector(rng: random.Random) -> list[float]:
    """Vector aleatório na esfera unitária.

    Os embeddings reais (facenet) são normalizados, por isso normalizar aqui
    mantém a distribuição de distâncias cosseno na mesma gama do que se mede
    em produção.
    """
    values = [rng.gauss(0.0, 1.0) for _ in range(DIM)]
    norm = math.sqrt(sum(v * v for v in values)) or 1.0
    return [v / norm for v in values]


def _noisy_variant(vec: list[float], rng: random.Random) -> list[float]:
    """Outra captura da mesma "pessoa": o mesmo vector com ruído gaussiano."""
    noisy = [v + rng.gauss(0.0, PROBE_NOISE_SIGMA) for v in vec]
    norm = math.sqrt(sum(v * v for v in noisy)) or 1.0
    return [v / norm for v in noisy]


def _vector_literal(vec: list[float]) -> str:
    return "[" + ",".join(f"{v:.6f}" for v in vec) + "]"


@pytest.fixture(scope="module")
def conn():
    connection = psycopg2.connect(STRESS_DSN)
    connection.autocommit = True
    with connection.cursor() as cur:
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
    yield connection
    with connection.cursor() as cur:
        cur.execute(f"DROP TABLE IF EXISTS {TABLE}")
    connection.close()


def _create_table(conn) -> None:
    with conn.cursor() as cur:
        cur.execute(f"DROP TABLE IF EXISTS {TABLE}")
        cur.execute(
            f"""
            CREATE TABLE {TABLE} (
                id                 text PRIMARY KEY,
                tenant_id          varchar(36),
                erp_user_id        varchar(50) NOT NULL,
                model_version      varchar(50) NOT NULL,
                transform_version  varchar(30),
                status             varchar(20) NOT NULL,
                embedding_vector   vector({DIM})
            )
            """
        )


def _populate(conn, total: int, n_tenants: int, rng: random.Random) -> list[list[float]]:
    """Insere `total` templates sintéticos distribuídos por `n_tenants`.

    Devolve os vectores inseridos, para poder derivar probes deles.
    """
    batch_size = 1000
    vectors: list[list[float]] = []
    rows: list[tuple] = []
    insert_sql = (
        f"INSERT INTO {TABLE} (id, tenant_id, erp_user_id, model_version,"
        f" transform_version, status, embedding_vector)"
        f" VALUES (%s,%s,%s,%s,%s,%s,%s)"
    )
    with conn.cursor() as cur:
        for i in range(total):
            vec = _random_unit_vector(rng)
            vectors.append(vec)
            rows.append(
                (
                    f"tpl-{i}",
                    f"tenant-{i % n_tenants}",
                    str(i),
                    MODEL_VERSION,
                    TRANSFORM_VERSION,
                    "ACTIVE",
                    _vector_literal(vec),
                )
            )
            if len(rows) >= batch_size:
                execute_batch(cur, insert_sql, rows, page_size=batch_size)
                rows = []
        if rows:
            execute_batch(cur, insert_sql, rows, page_size=batch_size)
        cur.execute(f"ANALYZE {TABLE}")
    return vectors


def _build_index(conn) -> float:
    """Cria o índice HNSW e devolve o tempo de construção em segundos."""
    started = time.perf_counter()
    with conn.cursor() as cur:
        cur.execute(
            f"CREATE INDEX {INDEX} ON {TABLE} USING hnsw (embedding_vector vector_cosine_ops)"
            f" WITH (m = {HNSW_M}, ef_construction = {HNSW_EF_CONSTRUCTION})"
        )
        cur.execute(f"ANALYZE {TABLE}")
    return time.perf_counter() - started


def _drop_index(conn) -> None:
    with conn.cursor() as cur:
        cur.execute(f"DROP INDEX IF EXISTS {INDEX}")


# A query espelha a de identify_biometric: mesmos filtros de igualdade, mesma
# ordenação por distância cosseno (`<=>`) e mesmo LIMIT top_k.
_QUERY = f"""
    SELECT erp_user_id, embedding_vector <=> %s::vector AS distance
      FROM {TABLE}
     WHERE tenant_id = %s
       AND status = 'ACTIVE'
       AND model_version = %s
       AND transform_version = %s
       AND embedding_vector IS NOT NULL
     ORDER BY embedding_vector <=> %s::vector
     LIMIT {TOP_K}
"""


def _search(conn, probe: str, tenant: str, exact: bool) -> tuple[list[tuple[str, float]], float]:
    """Corre a query e devolve ([(erp_user_id, distância)], latência em ms).

    `exact=True` desliga os index scans para forçar a busca exacta, que serve
    de ground truth.
    """
    with conn.cursor() as cur:
        if exact:
            cur.execute("SET LOCAL enable_indexscan = off")
            cur.execute("SET LOCAL enable_bitmapscan = off")
        started = time.perf_counter()
        cur.execute(_QUERY, (probe, tenant, MODEL_VERSION, TRANSFORM_VERSION, probe))
        rows = cur.fetchall()
        elapsed_ms = (time.perf_counter() - started) * 1000
    return [(row[0], float(row[1])) for row in rows], elapsed_ms


def _usa_indice_hnsw(conn, probe: str, tenant: str) -> bool:
    """Confirma pelo plano de execução que a query usa mesmo o índice HNSW.

    Sem esta verificação o benchmark mede o que o planeador decidir: com
    poucas linhas por tenant o Postgres escolhe sequential scan, e os números
    apareceriam como "HNSW" sendo na verdade busca exacta — com recall 1.000
    trivial e latência que não representa o índice.
    """
    with conn.cursor() as cur:
        cur.execute(
            "EXPLAIN (FORMAT JSON) " + _QUERY,
            (probe, tenant, MODEL_VERSION, TRANSFORM_VERSION, probe),
        )
        plan = json.dumps(cur.fetchone()[0])
    return INDEX in plan


def _percentiles(samples: list[float]) -> dict[str, float]:
    ordered = sorted(samples)

    def pct(p: float) -> float:
        idx = min(int(math.ceil(p / 100 * len(ordered))) - 1, len(ordered) - 1)
        return ordered[max(idx, 0)]

    return {
        "p50": round(statistics.median(ordered), 2),
        "p95": round(pct(95), 2),
        "p99": round(pct(99), 2),
        "max": round(ordered[-1], 2),
    }


def _preparar_probes(vectors: list[list[float]], n_tenants: int, rng: random.Random):
    """Gera probes derivadas de linhas existentes.

    Devolve [(literal da probe, tenant da linha de origem, erp_user_id
    esperado)]. O tenant é o da linha escolhida — de outra forma a query
    filtrava para fora a própria pessoa que se procura.
    """
    probes = []
    for _ in range(_n_queries()):
        idx = rng.randrange(len(vectors))
        probes.append(
            (
                _vector_literal(_noisy_variant(vectors[idx], rng)),
                f"tenant-{idx % n_tenants}",
                str(idx),
            )
        )
    return probes


@pytest.mark.parametrize("total", _counts())
@pytest.mark.parametrize("n_tenants", _tenant_counts())
def test_stress_identify_1n(conn, total: int, n_tenants: int, capsys) -> None:
    """Compara latência e qualidade entre busca exacta e HNSW.

    Não impõe limiares de latência: o número absoluto depende inteiramente da
    máquina onde corre, e um assert desses só produziria falhas intermitentes.
    O que é verificado é o que tem de ser verdade em qualquer máquina — que a
    busca encontra a pessoa certa e que o isolamento por tenant se mantém. Os
    números medidos são impressos para registo.
    """
    rng = random.Random(1234)
    _create_table(conn)
    vectors = _populate(conn, total, n_tenants, rng)
    probes = _preparar_probes(vectors, n_tenants, rng)

    # ── 1. Busca exacta (ground truth + baseline de latência) ────────────────
    _drop_index(conn)
    exact_results = []
    exact_latencies = []
    for probe, tenant, _ in probes:
        rows, ms = _search(conn, probe, tenant, exact=True)
        exact_results.append(rows)
        exact_latencies.append(ms)

    # ── 2. Busca com índice HNSW ─────────────────────────────────────────────
    build_seconds = _build_index(conn)
    indice_usado = _usa_indice_hnsw(conn, probes[0][0], probes[0][1])
    hnsw_results = []
    hnsw_latencies = []
    for probe, tenant, _ in probes:
        rows, ms = _search(conn, probe, tenant, exact=False)
        hnsw_results.append(rows)
        hnsw_latencies.append(ms)

    # ── 3. Qualidade ─────────────────────────────────────────────────────────
    # top1_correcto: a busca exacta devolveu mesmo a pessoa de quem a probe
    # foi derivada (valida o gerador de dados, não o índice).
    top1_exacto = statistics.mean(
        1.0 if rows and rows[0][0] == esperado else 0.0
        for rows, (_, _, esperado) in zip(exact_results, probes)
    )
    # recall_hnsw: o HNSW encontra a pessoa certa no top-k. É esta a métrica
    # que corresponde ao que o identify faz em produção.
    recall_hnsw = statistics.mean(
        1.0 if any(uid == esperado for uid, _ in rows) else 0.0
        for rows, (_, _, esperado) in zip(hnsw_results, probes)
    )

    exact_stats = _percentiles(exact_latencies)
    hnsw_stats = _percentiles(hnsw_latencies)
    rows_per_tenant = total // n_tenants
    speedup = exact_stats["p50"] / hnsw_stats["p50"] if hnsw_stats["p50"] else float("nan")

    with capsys.disabled():
        print(
            f"\n── 1:N stress — {total} templates, {n_tenants} tenant(s)"
            f" ({rows_per_tenant} linhas/tenant), top_k={TOP_K}, {len(probes)} queries"
        )
        print(f"   construção do índice HNSW : {build_seconds:.1f}s")
        print(f"   índice HNSW usado no plano: {indice_usado}")
        print(f"   exacta (seq scan)  ms     : {exact_stats}")
        print(f"   HNSW               ms     : {hnsw_stats}")
        print(f"   speedup (p50)             : {speedup:.1f}x")
        print(f"   top-1 correcto (exacta)   : {top1_exacto:.3f}")
        print(f"   recall@{TOP_K} (HNSW)          : {recall_hnsw:.3f}")

    # A busca exacta tem de encontrar sempre a pessoa certa: a probe é a mesma
    # pessoa com ruído calibrado para ~0.85 de similaridade. Se isto falhar, é
    # o gerador de dados que está errado, não o pgvector.
    assert top1_exacto > 0.99, (
        f"Busca exacta só acertou o top-1 em {top1_exacto:.1%} das probes — "
        "o ruído da probe está alto demais para o teste significar alguma coisa."
    )

    # Nota: esta recall é medida com o `hnsw.ef_search` por omissão (40), que é
    # o que produção usa — `identify_biometric` nunca define este parâmetro. A
    # recall degrada com o volume: ~0.98 a 10k templates, ~0.75 a 100k. O valor
    # de ef_search necessário para a recuperar é medido em
    # test_ef_search_necessario_para_recall, que é onde está o número accionável.
    #
    # O assert aqui é só um piso de sanidade: recall muito baixa significaria
    # que o índice está a descartar quase todos os candidatos correctos, o modo
    # de falha que passa despercebido em produção (o identify devolveria
    # "no_candidate_above_threshold" em vez de erro).
    assert recall_hnsw > 0.5, (
        f"HNSW só encontrou a pessoa certa em {recall_hnsw:.1%} das probes com "
        f"{total} templates e {n_tenants} tenants (índice usado: {indice_usado}). "
        "Ver test_ef_search_necessario_para_recall para o ef_search adequado."
    )

    # Isolamento por tenant: nenhuma linha devolvida pode ser de outro tenant.
    probe, tenant, _ = probes[0]
    with conn.cursor() as cur:
        cur.execute(_QUERY, (probe, tenant, MODEL_VERSION, TRANSFORM_VERSION, probe))
        returned = [row[0] for row in cur.fetchall()]
        if returned:
            cur.execute(
                f"SELECT COUNT(*) FROM {TABLE} WHERE erp_user_id = ANY(%s) AND tenant_id <> %s",
                (returned, tenant),
            )
            assert cur.fetchone()[0] == 0, "Busca 1:N devolveu templates de outro tenant"


EF_SEARCH_SWEEP = (40, 100, 200, 400, 800)
RECALL_ALVO = 0.95


@pytest.mark.parametrize("total", [max(_counts())])
def test_ef_search_necessario_para_recall(conn, total: int, capsys) -> None:
    """Mede a recall e a latência em função de `hnsw.ef_search`.

    `ef_search` controla quantos candidatos o HNSW visita antes de parar. O
    valor por omissão do pgvector é 40 e `identify_biometric` nunca o altera,
    o que é suficiente a 10k templates mas não a 100k (ver a medição no teste
    anterior). Este teste produz o número accionável: o menor `ef_search` que
    devolve a pessoa certa em pelo menos 95% das probes, e o que isso custa em
    latência.

    O índice é construído uma única vez e reutilizado em toda a varredura — a
    construção é a parte cara (minutos a 100k), a varredura em si é barata.
    """
    rng = random.Random(99)
    _create_table(conn)
    vectors = _populate(conn, total, 1, rng)
    probes = _preparar_probes(vectors, 1, rng)

    # Ground truth exacto, antes de existir índice.
    _drop_index(conn)
    esperados = [esperado for _, _, esperado in probes]
    exatos = [_search(conn, p, t, exact=True)[0] for p, t, _ in probes]
    top1_exacto = statistics.mean(
        1.0 if rows and rows[0][0] == esperado else 0.0
        for rows, esperado in zip(exatos, esperados)
    )

    build_seconds = _build_index(conn)

    # O plano é capturado a cada passo porque o custo estimado do index scan
    # HNSW cresce com ef_search: a partir de certo ponto o planeador acha o
    # sequential scan mais barato e deixa de usar o índice. Sem registar isto,
    # a varredura mistura medições de índice com medições de seq scan e produz
    # uma curva não-monótona sem explicação (recall 1.000 "de graça", latência
    # a saltar para os segundos).
    medicoes: list[tuple[int, float, float, bool]] = []
    for ef_search in EF_SEARCH_SWEEP:
        acertos = []
        latencias = []
        with conn.cursor() as cur:
            cur.execute(f"SET hnsw.ef_search = {ef_search}")
        usou_indice = _usa_indice_hnsw(conn, probes[0][0], probes[0][1])
        for (probe, tenant, esperado) in probes:
            with conn.cursor() as cur:
                cur.execute(f"SET hnsw.ef_search = {ef_search}")
                started = time.perf_counter()
                cur.execute(_QUERY, (probe, tenant, MODEL_VERSION, TRANSFORM_VERSION, probe))
                rows = cur.fetchall()
                latencias.append((time.perf_counter() - started) * 1000)
            acertos.append(1.0 if any(row[0] == esperado for row in rows) else 0.0)
        medicoes.append(
            (ef_search, statistics.mean(acertos), statistics.median(latencias), usou_indice)
        )

    # Só contam os pontos em que o índice foi mesmo usado: um ponto com recall
    # 1.000 obtida por sequential scan não é uma recomendação de ef_search, é o
    # planeador a desistir do índice.
    suficientes = [ef for ef, recall, _, usou in medicoes if recall >= RECALL_ALVO and usou]

    with capsys.disabled():
        print(f"\n── ef_search vs. recall@{TOP_K} ({total} templates, 1 tenant)")
        print(f"   construção do índice HNSW : {build_seconds:.1f}s")
        print(f"   top-1 correcto (exacta)   : {top1_exacto:.3f}")
        for ef_search, recall, p50, usou in medicoes:
            plano = "HNSW    " if usou else "seq scan"
            marca = " ← suficiente" if recall >= RECALL_ALVO and usou else ""
            print(
                f"   ef_search {ef_search:>4} → {plano} recall {recall:.3f},"
                f" p50 {p50:8.2f} ms{marca}"
            )
        if suficientes:
            print(f"   menor ef_search com recall ≥ {RECALL_ALVO} via índice: {min(suficientes)}")

    assert suficientes, (
        f"Nenhum ef_search até {max(EF_SEARCH_SWEEP)} atingiu recall {RECALL_ALVO} usando o "
        f"índice, com {total} templates. Medições (ef, recall, p50, usou_índice): {medicoes}"
    )


@pytest.mark.parametrize("total", [max(_counts())])
def test_planeador_escolhe_hnsw_conforme_linhas_por_tenant(conn, total: int, capsys) -> None:
    """Documenta quando é que o índice HNSW é de facto usado.

    O índice da migration `76692ef15c1a` cobre apenas `embedding_vector`; os
    filtros de `tenant_id`/`status`/`model_version` são aplicados depois. Com
    poucas linhas por tenant o planeador prefere sequential scan — o que é a
    decisão certa, mas significa que o índice não ajuda nesses tenants.

    Este teste mede a partir de que ponto o índice entra ao serviço, em vez de
    o assumir. É o input para decidir se vale a pena um índice parcial por
    tenant.
    """
    rng = random.Random(4321)
    medicoes: list[tuple[int, int, bool, float]] = []

    for n_tenants in (1, 100):
        _create_table(conn)
        vectors = _populate(conn, total, n_tenants, rng)
        probes = _preparar_probes(vectors, n_tenants, rng)
        _build_index(conn)
        usado = _usa_indice_hnsw(conn, probes[0][0], probes[0][1])
        latencias = [_search(conn, p, t, exact=False)[1] for p, t, _ in probes]
        medicoes.append((n_tenants, total // n_tenants, usado, statistics.median(latencias)))

    with capsys.disabled():
        print(f"\n── Uso do índice HNSW vs. linhas por tenant ({total} templates)")
        for n_tenants, por_tenant, usado, p50 in medicoes:
            print(
                f"   {n_tenants:>4} tenant(s), {por_tenant:>7} linhas/tenant"
                f" → índice usado: {str(usado):<5} p50 {p50:.2f} ms"
            )

    # Com um único tenant todas as linhas passam o filtro: aqui o índice tem
    # de ser usado, caso contrário a migration do HNSW não está a servir para
    # nada e o problema é de configuração, não de selectividade.
    assert medicoes[0][2], "Com 1 tenant o planeador não usou o índice HNSW"
