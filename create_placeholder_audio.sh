#!/bin/bash
# Create silent placeholder audio files for testing
# These are just for testing - replace with real audio later

echo "Creating placeholder audio files for testing..."

BASE_DIR="spelling-bee iOS App/Resources/Audio/Lisa/sentences"

# Create a 2-second silent WAV file
create_silent_wav() {
    local output_file="$1"
    # Create 2 seconds of silence at 44.1kHz, 16-bit, mono
    ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 2 -acodec pcm_s16le "$output_file" -y 2>/dev/null
}

# Read JSON and create files
python3 - <<'EOF'
import json
import os
import subprocess

with open("SENTENCES_AUDIO_BATCH.json", "r") as f:
    data = json.load(f)

base_dir = "spelling-bee iOS App/Resources/Audio/Lisa/sentences"
created = 0

for sentence in data["sentences"]:
    output_path = os.path.join(base_dir, sentence["outputFile"])

    # Skip if already exists
    if os.path.exists(output_path):
        continue

    # Create parent directory
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Create 2-second silent audio file
    result = subprocess.run(
        ["ffmpeg", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
         "-t", "2", "-acodec", "pcm_s16le", output_path, "-y"],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        created += 1
        if created % 50 == 0:
            print(f"Created {created} files...")
    else:
        print(f"Failed: {output_path}")

print(f"\n✅ Created {created} placeholder audio files")
print(f"⚠️  Note: These are silent placeholders for testing only")
print(f"📝 Replace with real audio using: python3 generate_audio_files.py")
EOF
