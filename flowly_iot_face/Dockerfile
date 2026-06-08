# Microserviço facial — Google Cloud Run / Docker
# Requer memória ≥ 2 GB (recomendado 4 GB) por causa do TensorFlow + DeepFace

FROM python:3.11-slim-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

ENV HOST=0.0.0.0
ENV PORT=8080
ENV FACE_MODEL=VGG-Face
ENV FACE_DETECTOR=opencv
ENV FACE_MATCH_THRESHOLD=0.4

EXPOSE 8080

# Cloud Run injeta PORT; gunicorn com 1 worker evita carregar o modelo várias vezes
CMD exec gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 4 --timeout 120 main:app
