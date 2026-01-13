# Audio Generation Guide

This guide explains how to generate the 720 sentence audio files needed for the "Use the word in a sentence" feature.

## 📁 Generated Files

| File | Description | Size |
|------|-------------|------|
| `SENTENCES_AUDIO_BATCH.json` | Complete dataset with all 720 sentences in JSON format | 151 KB |
| `SENTENCES_FOR_AUDIO.csv` | CSV export for easy import into audio tools | 70 KB |
| `generate_sentences_json.py` | Python script that generates the JSON file | - |
| `generate_audio_files.py` | Python script for automated audio generation | - |
| `export_sentences_csv.py` | Python script to export CSV | - |

## 🎯 Quick Start

### Option 1: Use the JSON File (Recommended)

The `SENTENCES_AUDIO_BATCH.json` file contains all 720 sentences in a structured format perfect for programmatic audio generation.

**Structure:**
```json
{
  "metadata": {
    "total_files": 720,
    "voice": "Lisa",
    "format": "WAV (44.1kHz, 16-bit, mono)"
  },
  "sentences": [
    {
      "difficulty": 1,
      "word": "cat",
      "sentenceNumber": 1,
      "text": "The cat is sleeping on the couch.",
      "outputFile": "difficulty_1/cat_sentence1.wav"
    },
    ...
  ]
}
```

### Option 2: Use the CSV File

The `SENTENCES_FOR_AUDIO.csv` file can be imported into:
- Google Sheets / Excel for manual review
- Audio generation web services (ElevenLabs, Play.ht, etc.)
- Custom scripts and tools

**CSV Columns:**
1. Difficulty (1-12)
2. Word
3. Sentence Number (1-3)
4. Text (the sentence to speak)
5. Output Filename (where to save the audio)

## 🎙️ Audio Generation Options

### Method 1: ElevenLabs API (Recommended)

**Cost:** ~$0.30 per 1,000 characters (estimated $15-20 for all 720 files)

**Steps:**
1. Sign up at [elevenlabs.io](https://elevenlabs.io)
2. Get your API key from the dashboard
3. Find your voice ID (or use a preset like "Lisa")
4. Set environment variable:
   ```bash
   export TTS_API_KEY="your-api-key-here"
   ```
5. Run the generation script:
   ```bash
   python3 generate_audio_files.py
   ```

**Configuration:**
Edit `generate_audio_files.py` and set:
```python
API_SERVICE = "elevenlabs"
VOICE_ID = "your-voice-id"
```

### Method 2: Play.ht API

**Cost:** Subscription-based, unlimited generation

**Steps:**
1. Sign up at [play.ht](https://play.ht)
2. Get API credentials
3. Configure and run the script (similar to ElevenLabs)

### Method 3: Google Cloud Text-to-Speech

**Cost:** $4 per 1 million characters (estimated $1-2 for all files)

**Steps:**
1. Enable Google Cloud TTS API
2. Download service account credentials
3. Set environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/credentials.json"
   ```
4. Install library:
   ```bash
   pip install google-cloud-texttospeech
   ```
5. Run script:
   ```bash
   python3 generate_audio_files.py
   ```

**Configuration:**
Edit `generate_audio_files.py`:
```python
API_SERVICE = "google"
VOICE_ID = "en-US-Neural2-F"  # Female voice
```

### Method 4: Manual Generation (Web Interface)

For manual generation using web interfaces:

1. Open `SENTENCES_FOR_AUDIO.csv` in Excel/Google Sheets
2. Use a text-to-speech web service (ElevenLabs, Play.ht, etc.)
3. For each row:
   - Copy the "Text" column
   - Generate audio in the web interface
   - Save with the filename from "Output Filename" column
   - Place in the correct difficulty folder

## 📂 File Organization

After generation, place files in this structure:

```
spelling-bee iOS App/Resources/Audio/Lisa/sentences/
├── difficulty_1/
│   ├── cat_sentence1.wav
│   ├── cat_sentence2.wav
│   ├── cat_sentence3.wav
│   └── ... (60 files total)
├── difficulty_2/
│   └── ... (60 files)
...
└── difficulty_12/
    └── ... (60 files)
```

✅ **Folders already exist** - created by previous setup step

## 🎚️ Audio Specifications

All audio files must meet these specifications:

| Specification | Value |
|---------------|-------|
| Format | WAV (uncompressed) |
| Sample Rate | 44,100 Hz (44.1 kHz) |
| Bit Depth | 16-bit |
| Channels | Mono (1 channel) |
| Voice | Lisa (AI voice, friendly, child-appropriate) |
| Speaking Rate | Normal (not too fast, not too slow) |
| Emotion/Tone | Friendly, clear, encouraging |

## 🔍 Verification

After generation, verify your files:

### Check File Count
```bash
find "spelling-bee iOS App/Resources/Audio/Lisa/sentences" -name "*.wav" | wc -l
```
Should output: **720**

### Check File Format
```bash
file "spelling-bee iOS App/Resources/Audio/Lisa/sentences/difficulty_1/cat_sentence1.wav"
```
Should show: `WAVE audio, Microsoft PCM, 16 bit, mono 44100 Hz`

### Test Playback
```bash
afplay "spelling-bee iOS App/Resources/Audio/Lisa/sentences/difficulty_1/cat_sentence1.wav"
```

## 🐛 Troubleshooting

### Issue: Rate Limiting

If you hit API rate limits:
1. Increase `PAUSE_SECONDS` in `generate_audio_files.py`
2. Reduce `BATCH_SIZE`
3. Run script multiple times (it skips existing files)

### Issue: Incorrect Audio Format

Convert files to correct format:
```bash
ffmpeg -i input.wav -ar 44100 -ac 1 -sample_fmt s16 output.wav
```

### Issue: Files Too Large

WAV files can be large (5-10MB each). To reduce size:
- Use compressed formats during generation
- Convert to WAV after downloading
- Compress using FLAC first, then convert to WAV

### Issue: Missing Files

Check which files are missing:
```bash
python3 -c "
import json
import os

with open('SENTENCES_AUDIO_BATCH.json') as f:
    data = json.load(f)

base = 'spelling-bee iOS App/Resources/Audio/Lisa/sentences'
missing = []
for s in data['sentences']:
    path = os.path.join(base, s['outputFile'])
    if not os.path.exists(path):
        missing.append(s['outputFile'])

print(f'Missing {len(missing)} files:')
for m in missing[:20]:
    print(f'  - {m}')
if len(missing) > 20:
    print(f'  ... and {len(missing)-20} more')
"
```

## 💰 Cost Estimates

| Service | Total Cost (720 files) | Notes |
|---------|------------------------|-------|
| ElevenLabs | $15-20 | ~50,000 characters total |
| Play.ht | $29-39/month | Subscription, unlimited |
| Google Cloud TTS | $1-2 | Pay per character |
| Manual | $0 | Time-consuming |

## ⏱️ Time Estimates

| Method | Estimated Time |
|--------|----------------|
| Automated Script | 1-2 hours (with pauses) |
| Manual Web Interface | 10-15 hours |
| Batch Upload | 2-3 hours |

## 🎬 Next Steps

After generating audio files:

1. ✅ Verify all 720 files exist
2. ✅ Check audio quality (spot check ~20 files)
3. ✅ Test in Xcode simulator:
   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
     -project spelling-bee.xcodeproj \
     -scheme "spelling-bee iOS App" \
     -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
     build
   ```
4. ✅ Test the "Use the word in a sentence" feature in-app
5. ✅ Submit to App Store (if all features work)

## 📞 Support

If you encounter issues:
1. Check the error messages in the terminal
2. Verify API keys and credentials
3. Test with a single file first before batch generation
4. Review audio specifications above

## 📝 Summary

- **Total files needed:** 720 WAV files
- **Total cost:** $1-20 depending on service
- **Total time:** 1-15 hours depending on method
- **Recommended:** ElevenLabs API for quality and speed
- **Budget option:** Google Cloud TTS for lowest cost
