FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev \
    cmake build-essential git \
    && rm -rf /var/lib/apt/lists/*

# Etapa 3 — PyTorch CPU-only (evita download da variante CUDA, ~750 MB menor)
RUN pip install --no-cache-dir \
    torch==2.3.1+cpu \
    torchvision==0.18.1+cpu \
    --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir facenet-pytorch==2.6.0 --no-deps

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Etapa 2 — modelos dlib para face_recognition
RUN pip install --no-cache-dir git+https://github.com/ageitgey/face_recognition_models

# Etapa 4 — dependências de runtime do facenet-pytorch removidas pelo --no-deps
# (o --no-deps evita puxar a variante CUDA do torch, mas também omite o tqdm)
RUN pip install --no-cache-dir tqdm

COPY . .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
