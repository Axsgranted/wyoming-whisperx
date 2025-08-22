FROM nvidia/cuda:12.2.0-base

RUN apt-get update && apt-get install -y \
    ffmpeg python3 python3-pip git \
    && pip3 install whisperx pyannote.audio torch wyoming \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && pip cache purge

COPY server.py /app/server.py
WORKDIR /app

CMD ["python3", "server.py"]
