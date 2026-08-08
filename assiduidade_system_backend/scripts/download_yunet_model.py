"""
Descarrega o modelo YuNet para detecao de faces.

YuNet e um detector de face leve da OpenCV Zoo, adequado para CPU e
self-hosted. O modelo e descarregado para app/ml_models/face_detection_yunet.onnx.
"""

from pathlib import Path

import urllib.request


YUNET_URL = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"


def download_yunet(output_path: Path) -> None:
    if output_path.is_file():
        print(f"Modelo ja existe em: {output_path}")
        return

    print(f"A descarregar YuNet para: {output_path}")
    urllib.request.urlretrieve(YUNET_URL, output_path)
    print("Descarga concluida.")


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parent.parent
    models_dir = project_root / "app" / "ml_models"
    models_dir.mkdir(parents=True, exist_ok=True)
    download_yunet(models_dir / "face_detection_yunet.onnx")
