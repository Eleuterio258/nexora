from app.services.face_detectors import (
    BlazeFaceDetector,
    get_face_detector,
    list_face_detectors,
    reset_face_detector_cache,
)


def test_list_face_detectors():
    detectors = list_face_detectors()
    assert "blaze_face" in detectors
    assert "yunet" in detectors


def test_get_face_detector_returns_cached_instance():
    reset_face_detector_cache()
    try:
        first = get_face_detector("blaze_face")
        second = get_face_detector("blaze_face")
        assert first is second
        assert isinstance(first, BlazeFaceDetector)
    finally:
        reset_face_detector_cache()


def test_reset_face_detector_cache_forces_new_instance():
    reset_face_detector_cache()
    try:
        first = get_face_detector("blaze_face")
        reset_face_detector_cache()
        second = get_face_detector("blaze_face")
        assert first is not second
    finally:
        reset_face_detector_cache()
