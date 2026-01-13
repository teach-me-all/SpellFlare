#!/usr/bin/env python3
"""
Generate audio files using gTTS (Google Text-to-Speech) - Free, no authentication required.
This uses the free Google Translate TTS API.

For better quality, use generate_audio_files.py with ElevenLabs or Google Cloud TTS.
"""

import json
import os
import sys
from pathlib import Path

try:
    from gtts import gTTS
except ImportError:
    print("❌ gTTS not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "gtts", "--quiet"])
    from gtts import gTTS

try:
    from pydub import AudioSegment
    HAS_PYDUB = True
except ImportError:
    print("⚠️  pydub not installed. Audio will be in MP3 format.")
    print("   To convert to WAV, install: pip install pydub")
    HAS_PYDUB = False

def convert_mp3_to_wav(mp3_path, wav_path):
    """Convert MP3 to WAV with correct specifications."""
    if not HAS_PYDUB:
        # Just rename if we can't convert
        os.rename(mp3_path, wav_path.replace('.wav', '.mp3'))
        return False

    try:
        # Load MP3
        audio = AudioSegment.from_mp3(mp3_path)

        # Convert to mono, 44.1kHz, 16-bit
        audio = audio.set_channels(1)  # Mono
        audio = audio.set_frame_rate(44100)  # 44.1 kHz
        audio = audio.set_sample_width(2)  # 16-bit

        # Export as WAV
        audio.export(wav_path, format="wav")

        # Remove temporary MP3
        os.remove(mp3_path)
        return True
    except Exception as e:
        print(f"   ⚠️  Conversion failed: {e}")
        return False

def generate_audio_gtts(text, output_path):
    """Generate audio using gTTS."""
    try:
        # Create directory if needed
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Generate TTS
        tts = gTTS(text=text, lang='en', slow=False)

        # Save as MP3 first
        temp_mp3 = output_path.replace('.wav', '_temp.mp3')
        tts.save(temp_mp3)

        # Convert to WAV if possible
        if HAS_PYDUB:
            success = convert_mp3_to_wav(temp_mp3, output_path)
            return success
        else:
            # Keep as MP3
            final_path = output_path.replace('.wav', '.mp3')
            os.rename(temp_mp3, final_path)
            return True

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    print("🎙️  Audio Generation using gTTS (Free)")
    print("=" * 60)
    print("⚠️  Note: gTTS provides basic quality TTS for free")
    print("   For professional quality, use ElevenLabs or Google Cloud TTS")
    print("=" * 60)
    print()

    # Load sentences
    with open("SENTENCES_AUDIO_BATCH.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    sentences = data["sentences"]
    base_dir = "spelling-bee iOS App/Resources/Audio/Lisa/sentences"

    print(f"📝 Total sentences: {len(sentences)}")
    print(f"📁 Output directory: {base_dir}")
    print()

    # First, remove all existing placeholder files
    print("🗑️  Removing placeholder files...")
    removed = 0
    for sentence in sentences:
        wav_path = os.path.join(base_dir, sentence["outputFile"])
        if os.path.exists(wav_path):
            os.remove(wav_path)
            removed += 1
    print(f"   Removed {removed} placeholder files\n")

    generated = 0
    failed = 0

    print("🎵 Generating audio files...")
    print("   This will take 15-30 minutes for all 720 files")
    print()

    for i, sentence in enumerate(sentences, start=1):
        word = sentence["word"]
        text = sentence["text"]
        output_file = sentence["outputFile"]
        output_path = os.path.join(base_dir, output_file)

        # Progress indicator
        if i % 10 == 0:
            print(f"[{i}/{len(sentences)}] Generated {generated}, Failed {failed}")

        # Generate audio
        success = generate_audio_gtts(text, output_path)

        if success:
            generated += 1
        else:
            failed += 1

    print()
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   ✅ Generated: {generated}")
    print(f"   ❌ Failed: {failed}")
    print(f"   📁 Total: {len(sentences)}")
    print("=" * 60)
    print()

    if not HAS_PYDUB:
        print("⚠️  Files are in MP3 format (AudioPlaybackService supports both)")
        print("   To convert to WAV: pip install pydub")
    else:
        print("✅ All files are in WAV format (44.1kHz, 16-bit, mono)")

    print()
    print("🎉 Done! You can now test the sentence feature in the app.")

if __name__ == "__main__":
    main()
