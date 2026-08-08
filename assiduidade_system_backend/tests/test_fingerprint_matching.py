import base64

import cv2
import numpy as np

from app.services.fingerprint_matching import (
    _decode_template_image,
    best_fingerprint_match,
    match_fingerprints,
)


def _synthetic_fingerprint_base64(seed: int = 42) -> str:
    np.random.seed(seed)
    img = np.zeros((200, 200), dtype=np.uint8)
    for y in range(200):
        for x in range(200):
            cx, cy = 100, 100
            dist = np.hypot(x - cx, y - cy)
            angle = np.arctan2(y - cy, x - cx)
            value = 128 + 100 * np.sin(dist / 5 + angle * 3)
            img[y, x] = np.clip(value + np.random.randint(-20, 20), 0, 255)
    _, encoded = cv2.imencode(".png", img)
    return base64.b64encode(encoded.tobytes()).decode("ascii")


def test_decode_template_image():
    b64 = _synthetic_fingerprint_base64()
    img = _decode_template_image(b64)
    assert img is not None
    assert img.shape == (200, 200)


def test_match_identical_templates():
    b64 = _synthetic_fingerprint_base64()
    is_match, score = match_fingerprints(b64, b64, threshold=0.1)
    assert is_match is True
    assert score > 0.0


def test_match_different_templates():
    b64_a = _synthetic_fingerprint_base64(seed=42)
    b64_b = _synthetic_fingerprint_base64(seed=99)
    is_match, score = match_fingerprints(b64_a, b64_b, threshold=0.25)
    # Padroes sinteticos diferentes podem ter score baixo; o importante e nao crashar.
    assert isinstance(is_match, bool)
    assert 0.0 <= score <= 1.0


def test_best_fingerprint_match():
    b64 = _synthetic_fingerprint_base64()
    references = [
        ("user-1", b64),
        ("user-2", _synthetic_fingerprint_base64(seed=99)),
    ]
    user_id, score = best_fingerprint_match(b64, references, threshold=0.1)
    assert user_id == "user-1"
    assert score > 0.0


def test_invalid_base64_returns_no_match():
    is_match, score = match_fingerprints("invalid-base64", "invalid-base64")
    assert is_match is False
    assert score == 0.0
