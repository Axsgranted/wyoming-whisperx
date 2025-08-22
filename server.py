from fastapi import FastAPI, UploadFile, File
from wyoming import WyomingSTT
import whisperx

app = FastAPI()
stt = WyomingSTT(model_name="whisperx", gpu=True)

@app.post("/asr")
async def transcribe(audio: UploadFile = File(...)):
    data = await audio.read()
    # Wyoming handles chunking and stitch-back
    result = stt.transcribe_bytes(data, sample_rate=int(os.getenv("WG_SAMPLE_RATE")))
    return {"text": result["text"], "segments": result["segments"]}
