import numpy as np
import pytest

from app.services.liveness_models import (
    AntiSpoofingONNXModel,
    HeuristicLivenessModel,
    get_liveness_model,
    list_liveness_models,
    reset_liveness_model_cache,
)


def test_list_liveness_models():
    models = list_liveness_models()
    assert "heuristic" in models
    assert "anti_spoofing" in models


def test_heuristic_liveness_score():
    model = HeuristicLivenessModel()
    img = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
    score = model.score(img)
    assert 0.0 <= score <= 1.0


def test_get_liveness_model_default():
    model = get_liveness_model("heuristic")
    assert isinstance(model, HeuristicLivenessModel)


def test_get_liveness_model_unknown():
    with pytest.raises(RuntimeError):
        get_liveness_model("unknown_model")


def test_anti_spoofing_model_scores_with_real_onnx():
    # app/ml_models/anti_spoofing.onnx e o MiniFASNetV2 80x80 do
    # Silent-Face-Anti-Spoofing (minivision-ai), convertido para ONNX.
    model = AntiSpoofingONNXModel()
    img = np.random.randint(0, 255, (200, 200, 3), dtype=np.uint8)
    score = model.score(img)
    assert 0.0 <= score <= 1.0


def test_anti_spoofing_model_returns_different_scores_for_different_inputs():
    model = AntiSpoofingONNXModel()
    img_a = np.full((128, 128, 3), 100, dtype=np.uint8)
    img_b = np.full((128, 128, 3), 200, dtype=np.uint8)
    score_a = model.score(img_a)
    score_b = model.score(img_b)
    # Entradas diferentes devem produzir scores diferentes (probabilistico).
    assert score_a != score_b


# ============================================================
# TESTES: Cache de modelos (get_liveness_model)
# ============================================================
def test_get_liveness_model_returns_cached_instance():
    reset_liveness_model_cache()
    try:
        first = get_liveness_model("heuristic")
        second = get_liveness_model("heuristic")
        assert first is second
    finally:
        reset_liveness_model_cache()


def test_reset_liveness_model_cache_forces_new_instance():
    reset_liveness_model_cache()
    try:
        first = get_liveness_model("heuristic")
        reset_liveness_model_cache()
        second = get_liveness_model("heuristic")
        assert first is not second
    finally:
        reset_liveness_model_cache()


# ============================================================
# TESTES: Simulacoes deterministicas de spoofing (PAD)
# ============================================================
class TestSpoofingSimulations:
    """Compara scores relativos (nao thresholds absolutos, que dependem de
    calibracao) entre imagens que simulam ataques e imagens com textura
    "viva". Contorna deliberadamente a deteccao real de face (que exige um
    rosto verdadeiro) chamando os modelos de liveness directamente."""

    def test_heuristic_scores_flat_image_lower_than_textured_image(self):
        model = HeuristicLivenessModel()
        # Imagem lisa: simula uma foto impressa ou reflexo de ecra sem
        # textura de pele nem variacao de frequencia.
        flat = np.full((200, 200, 3), 150, dtype=np.uint8)
        # Imagem com ruido gaussiano: simula variacao de textura de pele.
        rng = np.random.default_rng(1)
        textured = (150 + rng.normal(0, 40, (200, 200, 3))).clip(0, 255).astype(np.uint8)

        assert model.score(flat) < model.score(textured)

    def test_heuristic_scores_moire_pattern_lower_than_textured_image(self):
        model = HeuristicLivenessModel()
        # Padrao em grelha regular: simula o moire de um replay de ecra.
        grid = np.zeros((200, 200, 3), dtype=np.uint8)
        grid[::4, :, :] = 200
        grid[:, ::4, :] = 200
        rng = np.random.default_rng(2)
        textured = (150 + rng.normal(0, 40, (200, 200, 3))).clip(0, 255).astype(np.uint8)

        assert model.score(grid) < model.score(textured)

    def test_anti_spoofing_scores_stay_in_valid_range_for_attack_like_inputs(self):
        model = AntiSpoofingONNXModel()
        flat = np.full((128, 128, 3), 150, dtype=np.uint8)
        rng = np.random.default_rng(3)
        textured = (150 + rng.normal(0, 40, (128, 128, 3))).clip(0, 255).astype(np.uint8)

        score_flat = model.score(flat)
        score_textured = model.score(textured)
        assert 0.0 <= score_flat <= 1.0
        assert 0.0 <= score_textured <= 1.0
        assert score_flat != score_textured


# Nota: testes E2E via /biometric/verify ou /liveness/verify sem mocks (com
# deteccao real de face) ficam fora desta fase — exigiriam imagens reais com
# consentimento ou um gerador de faces sinteticas ainda nao validado contra
# os detectores (BlazeFace/YuNet). Ver docs/proximas-implementacoes-self-hosted.md.
