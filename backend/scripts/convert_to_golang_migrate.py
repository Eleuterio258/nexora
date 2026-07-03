#!/usr/bin/env python3
"""
Converte as migrações numeradas de backend/migrations/ para o formato do
https://github.com/golang-migrate/migrate (timestamp.up.sql / timestamp.down.sql).

Antes de correr:
  1. Certifica-te de que public.schema_migrations reflete o estado real.
  2. Faz backup da base de dados.

Depois de correr:
  1. Verifica os ficheiros gerados.
  2. Aplica backend/scripts/seed_golang_migrate.sql na BD para converter a
     tabela de tracking antiga no formato do golang-migrate.
  3. Usa backend/scripts/run_migrations.sh (migrate CLI) daqui em diante.
"""

import os
import re
import shutil
import sys
from pathlib import Path

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "migrations"
SCRIPTS_DIR = Path(__file__).resolve().parent
BASE_VERSION = 2026_06_29_00_00_00  # YYYYMMDDHHMMSS como int

VERSION_RE = re.compile(r"^(\d+)([a-z]?)_(.*)\.sql$")


def parse_version(filename: str):
    m = VERSION_RE.match(filename)
    if not m:
        return None
    num = int(m.group(1))
    suffix = m.group(2)
    desc = m.group(3)
    return (num, suffix, desc)


def main():
    applied_file = SCRIPTS_DIR / "applied_migrations.txt"

    old_files = [f for f in MIGRATIONS_DIR.iterdir() if f.is_file() and f.suffix == ".sql"]

    up_files = []
    down_files = []
    special = {}
    for f in old_files:
        name = f.name
        if name == "090_rollback_users_escopo.down.sql":
            special["rollback"] = f
            continue
        if name == "094_schema_migrations.sql":
            special["schema_migrations"] = f
            continue
        if name.endswith(".down.sql"):
            down_files.append(f)
            continue
        pv = parse_version(name)
        if pv:
            up_files.append((pv, f))
        else:
            print(f"A ignorar ficheiro não reconhecido: {name}")

    up_files.sort(key=lambda x: x[0])

    mapping = {}
    new_files = []

    for idx, (pv, old_path) in enumerate(up_files, start=1):
        version_int = BASE_VERSION + idx
        version_str = f"{version_int:014d}"
        desc = pv[2]
        new_name = f"{version_str}_{desc}.up.sql"
        new_path = MIGRATIONS_DIR / new_name

        shutil.copy2(old_path, new_path)
        mapping[old_path.name] = version_str
        new_files.append(new_path)
        print(f"{old_path.name} -> {new_name}")

    if "rollback" in special:
        rollback_src = special["rollback"]
        rollback_dst = SCRIPTS_DIR / "rollback_users_escopo.sql"
        shutil.move(str(rollback_src), str(rollback_dst))
        print(f"{rollback_src.name} -> {rollback_dst.relative_to(Path.cwd())} (manual)")

    if "schema_migrations" in special:
        special["schema_migrations"].unlink()
        print(f"Removida {special['schema_migrations'].name} (tabela gerida pelo migrate)")

    for _, old_path in up_files + down_files:
        old_path.unlink()
        print(f"Apagado {old_path.name}")

    # Gerar seed SQL
    seed_path = SCRIPTS_DIR / "seed_golang_migrate.sql"
    applied = []
    if applied_file.exists():
        applied = [line.strip() for line in applied_file.read_text().splitlines() if line.strip()]
    else:
        print("AVISO: applied_migrations.txt não encontrado; seed baseado apenas nos ficheiros convertidos.")
        applied = list(mapping.keys())

    mapped_versions = []
    unmapped = []
    for old_name in applied:
        if old_name in mapping:
            mapped_versions.append(mapping[old_name])
        else:
            unmapped.append(old_name)

    if unmapped:
        print("AVISO: versões antigas não mapeadas (não serão inseridas no seed):")
        for m in unmapped:
            print(f"  - {m}")

    seed_lines = [
        "-- Seed da tabela schema_migrations do golang-migrate.",
        "-- Executar uma única vez na base de dados existente antes de usar o migrate CLI.",
        "",
        "-- Preservar histórico antigo (opcional) e criar tabela no formato do migrate.",
        "ALTER TABLE IF EXISTS public.schema_migrations RENAME TO schema_migrations_legacy;",
        "",
        "CREATE TABLE IF NOT EXISTS public.schema_migrations (",
        "    version BIGINT NOT NULL PRIMARY KEY,",
        "    dirty BOOLEAN NOT NULL DEFAULT FALSE",
        ");",
        "",
    ]

    if mapped_versions:
        seed_lines.append("INSERT INTO public.schema_migrations (version, dirty) VALUES")
        seed_lines.append(",\n".join(f"    ({v}, FALSE)" for v in mapped_versions) + ";")
    else:
        seed_lines.append("-- Nenhuma versão aplicada registada.")

    seed_lines.append("")
    seed_path.write_text("\n".join(seed_lines), encoding="utf-8")
    print(f"\nGerado seed: {seed_path.relative_to(Path.cwd())}")
    print(f"Total de versões no seed: {len(mapped_versions)}")

    map_path = SCRIPTS_DIR / "migration_version_map.txt"
    map_lines = [f"{old} -> {new}" for old, new in mapping.items()]
    map_path.write_text("\n".join(map_lines), encoding="utf-8")
    print(f"Gerado mapa: {map_path.relative_to(Path.cwd())}")


if __name__ == "__main__":
    main()
