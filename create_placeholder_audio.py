#!/usr/bin/env python3
"""
Create silent placeholder WAV files for testing the sentence feature.
These are 2-second silent audio files in the correct format.
Replace with real audio files later using generate_audio_files.py
"""

import json
import os
import wave
import struct

def create_silent_wav(output_path, duration_seconds=2):
    """Create a silent WAV file with correct specifications."""
    sample_rate = 44100  # 44.1 kHz
    num_channels = 1     # Mono
    sample_width = 2     # 16-bit

    num_frames = int(sample_rate * duration_seconds)

    # Create directory if needed
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Write WAV file
    with wave.open(output_path, 'w') as wav_file:
        wav_file.setnchannels(num_channels)
        wav_file.setsampwidth(sample_width)
        wav_file.setframerate(sample_rate)

        # Write silent frames (all zeros)
        for _ in range(num_frames):
            # Write a silent sample (value 0)
            wav_file.writeframes(struct.pack('<h', 0))

def main():
    print("🎵 Creating placeholder audio files for testing...")
    print("⚠️  Note: These are silent files for testing only\n")

    # Load sentence data
    with open("SENTENCES_AUDIO_BATCH.json", "r") as f:
        data = json.load(f)

    sentences = data["sentences"]
    base_dir = "spelling-bee iOS App/Resources/Audio/Lisa/sentences"

    created = 0
    skipped = 0

    for i, sentence in enumerate(sentences, start=1):
        output_path = os.path.join(base_dir, sentence["outputFile"])

        # Skip if already exists
        if os.path.exists(output_path):
            skipped += 1
            continue

        # Create silent audio file
        try:
            create_silent_wav(output_path, duration_seconds=2)
            created += 1

            # Progress indicator
            if created % 50 == 0:
                print(f"[{i}/{len(sentences)}] Created {created} files...")
        except Exception as e:
            print(f"❌ Failed to create {output_path}: {e}")

    print(f"\n{'='*60}")
    print(f"✅ Created {created} placeholder audio files")
    print(f"⏭️  Skipped {skipped} existing files")
    print(f"📁 Total: {len(sentences)} files")
    print(f"{'='*60}\n")
    print(f"⚠️  IMPORTANT: These are silent placeholders for testing only!")
    print(f"📝 Generate real audio with: python3 generate_audio_files.py")
    print(f"📖 See AUDIO_GENERATION_GUIDE.md for full instructions")

if __name__ == "__main__":
    main()
