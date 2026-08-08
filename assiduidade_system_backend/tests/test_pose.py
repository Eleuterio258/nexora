import base64

import cv2
import numpy as np

from app.services import biometric


def _make_blank_image(width: int = 640, height: int = 480) -> str:
    img = np.zeros((height, width, 3), dtype=np.uint8)
    _, encoded = cv2.imencode(".jpg", img)
    return base64.b64encode(encoded.tobytes()).decode("ascii")


def test_assess_pose_invalid_image():
    ok, reason = biometric.assess_pose_and_occlusion(image_base64="not-base64!!!")
    assert ok is False
    assert reason == "invalid_image"


def test_assess_pose_no_face():
    b64 = _make_blank_image()
    ok, reason = biometric.assess_pose_and_occlusion(image_base64=b64)
    assert ok is False
    assert reason == "no_face_detected"


def test_estimate_head_pose_frontal():
    """Verifica que pontos de uma face frontal simulada produzem pose próxima de zero."""
    image_points = np.array(
        [
            [320.0, 240.0],  # nose
            [320.0, 380.0],  # chin
            [260.0, 200.0],  # left eye
            [380.0, 200.0],  # right eye
            [290.0, 290.0],  # left mouth
            [350.0, 290.0],  # right mouth
        ],
        dtype=np.float32,
    )

    pose = biometric._estimate_head_pose(image_points)
    assert pose is not None
    yaw, pitch, roll = pose
    assert abs(yaw) < 5.0
    assert abs(pitch) < 5.0
    assert abs(roll) < 5.0
