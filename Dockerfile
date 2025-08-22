FROM nvidia/cuda:12.2.0-base-ubuntu22.04

RUN apt update && apt install -y \
    ffmpeg python3 python3-pip git && \
    pip3 install whisperx pyannote.audio torch wyoming

COPY server.py /app/server.py
WORKDIR /app

CMD ["python3", "server.py"]