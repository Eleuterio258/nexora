# Anti-Spoofing ONNX — Guia Self-Hosted

**Data:** 2026-08-05 (última actualização: 2026-08-08)
**Sistema:** FaceClock (`assiduidade_system_backend/`)

---

## Visão geral

O FaceClock suporta liveness passiva via modelo ONNX. Por omissão usa uma heurística local (`LIVENESS_MODEL=heuristic`).

**Estado (2026-08-08): `app/ml_models/anti_spoofing.onnx` já é um modelo treinado real**, não o dummy — foi integrado o MiniFASNetV2 80×80 do Silent-Face-Anti-Spoofing (ver "Opção 1" abaixo, já feita). Falta só definir `LIVENESS_MODEL=anti_spoofing` (ver secção "Configuração") e calibrar o threshold antes de confiar nele em produção.

---

## Modelo dummy (testes/desenvolvimento)

O script `scripts/create_dummy_antispoofing_model.py` continua disponível para gerar um modelo ONNX dummy (pesos aleatórios) — útil para testar o carregamento/pipeline sem depender de um modelo real, mas **nunca deve ser usado em produção**. O modelo dummy aceita `float32[N, 3, 128, 128]` e devolve `float32[N, 2]`.

---

## Como obter um modelo real

### Opção 1 — Silent-Face-Anti-Spoofing (já integrado, referência para futuras trocas)

Modelo actualmente em uso: [minivision-ai/Silent-Face-Anti-Spoofing](https://github.com/minivision-ai/Silent-Face-Anti-Spoofing), checkpoint `2.7_80x80_MiniFASNetV2`, convertido para ONNX via [QingHeYang/Silent-Face-Anti-Spoofing-onnx](https://github.com/QingHeYang/Silent-Face-Anti-Spoofing-onnx) (também disponível em [Hugging Face](https://huggingface.co/garciafido/minifasnet-v2-anti-spoofing-onnx)).

Se precisares de repetir o processo ou trocar de checkpoint:

```bash
curl -o anti_spoofing.onnx \
  https://raw.githubusercontent.com/QingHeYang/Silent-Face-Anti-Spoofing-onnx/main/onnx/2.7_80x80_MiniFASNetV2.onnx
```

**Antes de substituir o ficheiro em produção**, verificar sempre o shape de input/output com `onnxruntime` (ver secção "Formato esperado do modelo" abaixo) — o input real é 80×80 (não 128×128) e o output tem 3 classes (não 2), e o código já foi ajustado para lidar com isto correctamente, mas um checkpoint diferente pode ter uma convenção de classes diferente.

### Opção 2 — Treinar modelo próprio

Se tiveres um dataset de rostos reais vs. ataques (foto, ecrã, máscara), podes treinar uma pequena CNN (MobileNetV2/ShuffleNet) e exportar para ONNX.

Requisitos mínimos do dataset:
- ≥ 10k imagens reais
- ≥ 10k imagens de ataque (vários tipos)
- balanceado por iluminação, câmara e demografia

---

## Configuração

```env
LIVENESS_MODEL=anti_spoofing
BIOMETRIC_LIVENESS_THRESHOLD=0.7
```

Instalar dependência:

```bash
pip install -r requirements-extras.txt
```

---

## Calibração do threshold

O threshold ideal depende do ambiente. Usa o endpoint de calibração com amostras reais:

```bash
curl -X POST https://faceclock.seu-dominio.com/api/v1/admin/biometric/calibrate-threshold \
  -H "..." \
  -d '{
    "target_far": 0.01,
    "metric": "eer"
  }'
```

Recomendações operacionais:

| Cenário | Threshold sugerido |
| --- | --- |
| Baixa segurança, alta usabilidade | 0.55 |
| Equilibrado | 0.70 |
| Alta segurança | 0.85 |

---

## Formato esperado do modelo

O `AntiSpoofingONNXModel` (`app/services/liveness_models.py`) suporta:

- **Input:** `NCHW` ou `NHWC` — o tamanho (largura/altura) é lido directamente do shape declarado pelo modelo ONNX no arranque (`_resolve_input_size`), com fallback para 128×128 só se a dimensão for simbólica/dinâmica (`batch_size`, `None`). **Não assumas 128×128** — o modelo actual (MiniFASNetV2) é 80×80.
- **Output:** suporta 1 classe (probabilidade única de "vivo"), 2 classes (softmax, índice 1 = vivo) ou **3 classes** (softmax, índice 1 = rosto real — convenção específica do MiniFASNet, confirmada contra o `test.py` oficial: `label = np.argmax(prediction); if label == 1: "Real Face"`; índices 0 e 2 são dois tipos de ataque, print e replay).

Se usares um modelo com número de classes diferente ou outra convenção de índices, **não confies no fallback genérico** (`probs[-1]`) sem verificar — a ordem errada das classes é um bug de segurança silencioso (aceita ataques como "vivo"), não um erro que apareça nos logs. Testa sempre com `onnxruntime` directamente antes de colocar em produção:

```python
import onnxruntime as ort
sess = ort.InferenceSession("anti_spoofing.onnx")
print(sess.get_inputs()[0].shape)   # confirmar largura/altura
print(sess.get_outputs()[0].shape)  # confirmar numero de classes
```

---

## Testar o modelo

```bash
cd assiduidade_system_backend
LIVENESS_MODEL=anti_spoofing ./venv/Scripts/python -m pytest tests/test_liveness_models.py -q
```

---

## Hardening

- Guarda o ficheiro `.onnx` com permissões restritas (`chmod 600`).
- Não exponhas o modelo em endpoints públicos.
- Considera assinar digitalmente o modelo para evitar troca.

---

## Limitações

- Modelos genéricos podem ter performance inferior em câmaras/iluminação específicas.
- Recomenda-se testar com amostras reais do teu ambiente antes de colocar em produção.
