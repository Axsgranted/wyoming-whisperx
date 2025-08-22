from wyoming.server import AsyncServer
from wyoming.audio import AudioChunk, AudioStop
from wyoming.stt import Transcript
import whisperx
import tempfile
import os

device = "cuda"
model = whisperx.load_model("large-v3", device=device)
diarize_model = whisperx.DiarizationPipeline(use_auth_token=None, device=device)

async def handle_audio(stream):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        async for message in stream:
            if isinstance(message, AudioChunk):
                f.write(message.audio)
            elif isinstance(message, AudioStop):
                break
        audio_path = f.name

    result = model.transcribe(audio_path)
    result = whisperx.align(result["segments"], model.audiodata, model.model, device)
    diarize_segments = diarize_model(audio_path)
    result = whisperx.assign_word_speakers(result, diarize_segments)

    os.remove(audio_path)

    text = "\n".join(
        [f"[{seg['speaker']}] {seg['text']}" for seg in result["segments"]]
    )
    return Transcript(text=text, language=result["language"])

async def main():
    server = AsyncServer("0.0.0.0", 10300)
    await server.run(handle_audio)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())