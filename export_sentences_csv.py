#!/usr/bin/env python3
"""
Export sentences to CSV format for easy import into audio generation tools.
"""

import json
import csv

def main():
    # Load JSON
    with open("SENTENCES_AUDIO_BATCH.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    sentences = data["sentences"]

    # Write to CSV
    with open("SENTENCES_FOR_AUDIO.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        # Header
        writer.writerow(["Difficulty", "Word", "Sentence Number", "Text", "Output Filename"])

        # Data rows
        for s in sentences:
            writer.writerow([
                s["difficulty"],
                s["word"],
                s["sentenceNumber"],
                s["text"],
                s["outputFile"]
            ])

    print(f"✅ Exported {len(sentences)} sentences to SENTENCES_FOR_AUDIO.csv")
    print(f"📁 File size: {len(sentences)} rows × 5 columns")

if __name__ == "__main__":
    main()
