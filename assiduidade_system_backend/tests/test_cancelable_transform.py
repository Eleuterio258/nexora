import pytest

from app.security.cancelable_transform import CancelableTransform


def test_transform_preserves_similarity():
    transform = CancelableTransform("secret-1")
    embedding = [1.0, 0.0, 0.0, 0.0]
    transformed = transform.transform(embedding)

    # A transformacao deve manter a norma unitaria.
    norm = sum(v * v for v in transformed) ** 0.5
    assert pytest.approx(norm, 0.001) == 1.0


def test_same_secret_same_transform():
    transform_a = CancelableTransform("secret-1")
    transform_b = CancelableTransform("secret-1")
    embedding = [0.5, 0.5, 0.5, 0.5]
    assert transform_a.transform(embedding) == pytest.approx(transform_b.transform(embedding))


def test_different_secret_different_transform():
    transform_a = CancelableTransform("secret-1")
    transform_b = CancelableTransform("secret-2")
    embedding = [0.5, 0.5, 0.5, 0.5]
    assert transform_a.transform(embedding) != pytest.approx(transform_b.transform(embedding))


def test_missing_secret_raises():
    with pytest.raises(RuntimeError):
        CancelableTransform("")
