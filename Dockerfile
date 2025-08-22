# Stage 1: Builder — compile wheels and install heavy deps
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHON_VERSION=3.11 \
    PIP_NO_CACHE_DIR=off \
    PIP_WHEEL_DIR=/wheels

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python${PYTHON_VERSION} \
      python${PYTHON_VERSION}-dev \
      python3-pip \
      build-essential \
      git \
      ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip, prepare wheel dir
RUN python3 -m pip install --upgrade pip setuptools wheel

# Copy requirements and wheel-build all
COPY requirements.txt /src/requirements.txt
WORKDIR /src
RUN pip download --dest /wheels --only-binary=:all: -r requirements.txt

# Stage 2: Final runtime
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=yes

# Install runtime deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3.11 \
      python3-pip \
      ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3.11 /usr/bin/python

# Copy and install wheels
COPY --from=builder /wheels /wheels
RUN pip install --upgrade pip setuptools && \
    pip install --no-index --find-links=/wheels \
      torch==2.1.0+cu121 \
      whisperx \
      wyoming \
      numpy \
      soundfile \
      torchvision && \
    rm -rf /wheels

# Copy entrypoint and default config
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose default Wyoming port for STT requests
EXPOSE 10300

HEALTHCHECK --interval=30s --timeout=5s \
  CMD nvidia-smi || exit 1

ENTRYPOINT ["entrypoint.sh"]
