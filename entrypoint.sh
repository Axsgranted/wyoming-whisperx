#!/usr/bin/env bash
set -e

# GPU visibility test
echo "Checking GPU..."
nvidia-smi

# Launch Wyoming STT server wrapping WhisperX
exec wyoming \
  --model whisperx-large-v2 \
  --device cuda \
  --chunk-length 30 \
  --backend torch \
  --port 10300
