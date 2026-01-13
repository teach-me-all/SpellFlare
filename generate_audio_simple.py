#!/usr/bin/env python3
"""
Generate audio files using gTTS (Google Text-to-Speech) - Free, no authentication required.
Saves as MP3 files which iOS AVAudioPlayer supports.
"""

import json
import os
import sys
import time

try:
    from gtts import gTTS
except ImportError:
    print("❌ gTTS not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "gtts", "--quiet"])
    from gtts import gTTS

def generate_audio_gtts(text, output_path):
    """Generate audio using gTTS and save as MP3."""
    try:
        # Create directory if needed
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Generate TTS
        tts = gTTS(text=text, lang='en', slow=False)

        # Save as MP3 (change extension)
        mp3_path = output_path.replace('.wav', '.mp3')
        tts.save(mp3_path)

        return True

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    print("🎙️  Audio Generation using gTTS (Free)")
    print("=" * 60)
    print("⚠️  Note: Files will be saved as MP3 (iOS supports this)")
    print("   For WAV format, install: brew install ffmpeg")
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
        mp3_path = wav_path.replace('.wav', '.mp3')

        if os.path.exists(wav_path):
            os.remove(wav_path)
            removed += 1
        if os.path.exists(mp3_path):
            os.remove(mp3_path)
            removed += 1

    print(f"   Removed {removed} files\n")

    generated = 0
    failed = 0
    start_time = time.time()

    print("🎵 Generating audio files...")
    print("   This will take 15-30 minutes for all 720 files")
    print("   Progress updates every 10 files\n")

    for i, sentence in enumerate(sentences, start=1):
        word = sentence["word"]
        text = sentence["text"]
        output_file = sentence["outputFile"]
        output_path = os.path.join(base_dir, output_file)

        # Progress indicator
        if i % 10 == 0:
            elapsed = time.time() - start_time
            rate = i / elapsed if elapsed > 0 else 0
            remaining = (len(sentences) - i) / rate if rate > 0 else 0
            remaining_min = remaining / 60

            print(f"[{i}/{len(sentences)}] Generated: {generated} | Failed: {failed} | "
                  f"ETA: {remaining_min:.1f} min")

        # Generate audio
        success = generate_audio_gtts(text, output_path)

        if success:
            generated += 1
        else:
            failed += 1
            print(f"   ⚠️  Failed: {word} - {text[:50]}")

    elapsed_total = time.time() - start_time

    print()
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   ✅ Generated: {generated}")
    print(f"   ❌ Failed: {failed}")
    print(f"   📁 Total: {len(sentences)}")
    print(f"   ⏱️  Time: {elapsed_total/60:.1f} minutes")
    print("=" * 60)
    print()
    print("📝 Files are in MP3 format (iOS AVAudioPlayer supports this)")
    print()
    print("🎉 Done! You can now test the sentence feature in the app.")

if __name__ == "__main__":
    main()
