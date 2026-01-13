#!/usr/bin/env python3
"""
Helper script to generate audio files from SENTENCES_AUDIO_BATCH.json
using text-to-speech services like ElevenLabs, Play.ht, or Google Cloud TTS.

Usage:
    1. Install required packages: pip install requests
    2. Set your API key as environment variable
    3. Run: python3 generate_audio_files.py
"""

import json
import os
import sys
import time
from pathlib import Path

# Configuration
API_SERVICE = "elevenlabs"  # Options: "elevenlabs", "playht", "google"
API_KEY = os.environ.get("TTS_API_KEY", "")
VOICE_ID = "lisa"  # Voice identifier for the service
OUTPUT_BASE_DIR = "spelling-bee iOS App/Resources/Audio/Lisa/sentences"
BATCH_SIZE = 10  # Number of files to generate before pausing
PAUSE_SECONDS = 2  # Pause between batches to avoid rate limits

def load_sentences():
    """Load sentences from JSON file."""
    with open("SENTENCES_AUDIO_BATCH.json", "r", encoding="utf-8") as f:
        data = json.load(f)
    return data["sentences"]

def generate_audio_elevenlabs(text, output_path, voice_id):
    """
    Generate audio using ElevenLabs API.
    Requires: pip install requests
    """
    import requests

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "Accept": "audio/wav",
        "Content-Type": "application/json",
        "xi-api-key": API_KEY
    }
    data = {
        "text": text,
        "model_id": "eleven_monolingual_v1",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
        }
    }

    response = requests.post(url, json=data, headers=headers)

    if response.status_code == 200:
        with open(output_path, "wb") as f:
            f.write(response.content)
        return True
    else:
        print(f"   ❌ Error: {response.status_code} - {response.text}")
        return False

def generate_audio_playht(text, output_path, voice_id):
    """
    Generate audio using Play.ht API.
    Requires: pip install requests
    """
    import requests

    # Note: This is a placeholder. Adjust according to Play.ht's actual API
    print(f"   ℹ️  Play.ht integration not implemented yet")
    return False

def generate_audio_google(text, output_path, voice_name):
    """
    Generate audio using Google Cloud Text-to-Speech.
    Requires: pip install google-cloud-texttospeech
    """
    try:
        from google.cloud import texttospeech
    except ImportError:
        print("   ❌ google-cloud-texttospeech not installed")
        return False

    client = texttospeech.TextToSpeechClient()

    synthesis_input = texttospeech.SynthesisInput(text=text)
    voice = texttospeech.VoiceSelectionParams(
        language_code="en-US",
        name=voice_name or "en-US-Neural2-F"
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16,
        sample_rate_hertz=44100
    )

    response = client.synthesize_speech(
        input=synthesis_input, voice=voice, audio_config=audio_config
    )

    with open(output_path, "wb") as f:
        f.write(response.audio_content)
    return True

def main():
    """Main generation loop."""
    if not API_KEY and API_SERVICE != "google":
        print("❌ Error: TTS_API_KEY environment variable not set")
        print("   Set it with: export TTS_API_KEY='your-api-key-here'")
        sys.exit(1)

    sentences = load_sentences()
    total = len(sentences)

    print(f"🎙️  Audio Generation Script")
    print(f"   Service: {API_SERVICE}")
    print(f"   Total files: {total}")
    print(f"   Output directory: {OUTPUT_BASE_DIR}")
    print()

    # Check if output directory exists
    Path(OUTPUT_BASE_DIR).mkdir(parents=True, exist_ok=True)

    generated = 0
    skipped = 0
    failed = 0

    for i, sentence in enumerate(sentences, start=1):
        word = sentence["word"]
        text = sentence["text"]
        output_file = sentence["outputFile"]
        output_path = os.path.join("spelling-bee iOS App/Resources/Audio/Lisa/sentences", output_file)

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Skip if file already exists
        if os.path.exists(output_path):
            print(f"[{i}/{total}] ⏭️  Skipping (exists): {output_file}")
            skipped += 1
            continue

        print(f"[{i}/{total}] 🎵 Generating: {word} (sentence {sentence['sentenceNumber']})")
        print(f"   Text: {text}")

        # Generate audio based on service
        success = False
        if API_SERVICE == "elevenlabs":
            success = generate_audio_elevenlabs(text, output_path, VOICE_ID)
        elif API_SERVICE == "playht":
            success = generate_audio_playht(text, output_path, VOICE_ID)
        elif API_SERVICE == "google":
            success = generate_audio_google(text, output_path, VOICE_ID)
        else:
            print(f"   ❌ Unknown service: {API_SERVICE}")
            sys.exit(1)

        if success:
            generated += 1
            print(f"   ✅ Saved: {output_path}")
        else:
            failed += 1

        # Pause after batch to avoid rate limits
        if (i % BATCH_SIZE == 0) and (i < total):
            print(f"\n⏸️  Pausing for {PAUSE_SECONDS}s to avoid rate limits...\n")
            time.sleep(PAUSE_SECONDS)

    print("\n" + "="*60)
    print(f"📊 Summary:")
    print(f"   ✅ Generated: {generated}")
    print(f"   ⏭️  Skipped: {skipped}")
    print(f"   ❌ Failed: {failed}")
    print(f"   📁 Total: {total}")
    print("="*60)

if __name__ == "__main__":
    main()
