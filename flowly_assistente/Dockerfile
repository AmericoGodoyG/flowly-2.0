FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY . .

# Environment padrão
ENV FLOWLY_API_BASE_URL=http://localhost:5000/api
ENV FLOWLY_DEBUG=false
ENV PORT=8080

# Expor porta
EXPOSE 8080

# Entrypoint: rodar HTTP server
CMD ["functions-framework", "--target", "trigger_http", "--port", "8080", "--host", "0.0.0.0"]
