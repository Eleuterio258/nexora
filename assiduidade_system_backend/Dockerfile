FROM python:3.12-slim

WORKDIR /app

# Cache partilhado entre o build e o utilizador de runtime. Sem isto o
# facenet-pytorch tenta descarregar os pesos VGGFace2 no primeiro pedido.
ENV TORCH_HOME=/app/.cache/torch

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev \
    libgles2 libegl1 \
    && rm -rf /var/lib/apt/lists/*

# Etapa 3 — PyTorch CPU-only (evita download da variante CUDA, ~750 MB menor)
RUN pip install --no-cache-dir \
    torch==2.3.1+cpu \
    torchvision==0.18.1+cpu \
    --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir facenet-pytorch==2.6.0 --no-deps

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Incorpora os pesos na imagem. O serviço não depende de internet nem de um
# cache em /root quando processa a primeira captura em produção.
RUN mkdir -p "$TORCH_HOME" && \
    python -c "from facenet_pytorch import InceptionResnetV1; InceptionResnetV1(pretrained='vggface2').eval(); print('FaceNet VGGFace2 weights cached')"

COPY . .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
