# Sentence Audio Files

This folder contains pre-generated audio files for sentences that use spelling words in context.

## Structure

```
sentences/
├── difficulty_1/     # Grade 1 words (cat, dog, sun, etc.)
├── difficulty_2/     # Grade 2 words (ball, tree, book, etc.)
├── difficulty_3/     # Grade 3 words (friend, school, write, etc.)
├── difficulty_4/     # Grade 4 words (beautiful, different, etc.)
├── difficulty_5/     # Grade 5 words (character, paragraph, etc.)
├── difficulty_6/     # Grade 6 words (accomplish, throughout, etc.)
├── difficulty_7/     # Grade 7 words (accommodate, achievement, etc.)
├── difficulty_8/     # Grade 8+ words
├── difficulty_9/     # Grade 9+ words
├── difficulty_10/    # Grade 10+ words
├── difficulty_11/    # Grade 11+ words
└── difficulty_12/    # Grade 12+ words
```

## File Naming Convention

Each word has 3 sentence variations:

```
{word}_sentence1.wav
{word}_sentence2.wav
{word}_sentence3.wav
```

Example for word "cat":
```
difficulty_1/cat_sentence1.wav
difficulty_1/cat_sentence2.wav
difficulty_1/cat_sentence3.wav
```

## Audio Generation

**Total files needed:** 720 audio files (240 words × 3 sentences each)

For complete sentence examples and audio generation instructions, see:
`/SENTENCES_FOR_AUDIO.md` in the project root.

## Audio Specifications

- **Format:** WAV (uncompressed)
- **Sample Rate:** 44.1 kHz
- **Bit Depth:** 16-bit
- **Channels:** Mono
- **Voice:** Lisa (AI voice from ElevenLabs or similar)
- **Style:** Clear, friendly, child-appropriate pronunciation

## How It's Used

When a student taps "Use the word in a sentence" during gameplay:
1. SentencePickerSheet displays 3 sentence options
2. Student selects a sentence
3. AudioPlaybackService plays the corresponding audio file
4. Student hears the word used in context to aid spelling

## Code References

- **Model:** `spelling-bee iOS App/Models/WordSentence.swift`
- **Service:** `spelling-bee iOS App/Services/AudioPlaybackService.swift` → `playSentence()`
- **UI:** `spelling-bee iOS App/Views/Game/GameView.swift` → `SentencePickerSheet`
