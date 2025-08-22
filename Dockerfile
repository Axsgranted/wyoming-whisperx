# Stage 1: Builder
FROM nvidia/cuda:11.8-devel-ubuntu22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-dev python3-pip build-essential ffmpeg git \
    && pip3 install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip3 wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Stage 2: Runtime
FROM nvidia/cuda:11.8-runtime-ubuntu22.04

# Strip unnecessary packages and locales
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && apt-get purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale /tmp/*

COPY --from=builder /wheels /wheels
RUN pip3 install --no-index --find-links=/wheels whisperx wyoming fastapi uvicorn[standard]

WORKDIR /app
COPY server.py .

ENV MODEL_NAME=whisperx \
    WG_CHUNK_SEC=10 \
    WG_SAMPLE_RATE=16000 \
    WG_GPU=true

EXPOSE 10300
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "10300"]
