//
//  WordBankService.swift
//  spelling-bee iOS App
//
//  Provides grade-appropriate spelling words.
//

import Foundation

class WordBankService {
    static let shared = WordBankService()

    private let wordsByDifficulty: [Int: [String]] = [
        1: ["cat", "dog", "sun", "run", "big", "red", "hat", "sit", "cup", "bed",
            "mom", "dad", "pet", "fun", "hot", "top", "box", "fox", "yes", "bus"],
        2: ["ball", "tree", "book", "fish", "bird", "cake", "play", "jump", "swim", "blue",
            "green", "happy", "water", "apple", "house", "mouse", "sleep", "dream", "smile", "light"],
        3: ["friend", "school", "write", "plant", "cloud", "train", "beach", "clean", "bring", "thing",
            "laugh", "watch", "catch", "match", "patch", "lunch", "bench", "branch", "crunch", "french"],
        4: ["beautiful", "different", "important", "together", "remember", "between", "another", "through", "thought", "brought",
            "daughter", "neighbor", "weight", "height", "straight", "caught", "taught", "bought", "fought", "sought"],
        5: ["character", "paragraph", "adventure", "attention", "celebrate", "community", "continue", "describe", "discover", "education",
            "especially", "experience", "favorite", "government", "important", "interested", "knowledge", "literature", "necessary", "particular"],
        6: ["accomplish", "throughout", "appreciate", "atmosphere", "boundaries", "challenge", "commercial", "competition", "concentrate", "conscience",
            "consequence", "consistent", "demonstrate", "development", "environment", "essentially", "exaggerate", "explanation", "extraordinary", "fascinating"],
        7: ["accommodate", "achievement", "acknowledge", "acquaintance", "advertisement", "anniversary", "anticipation", "appreciation", "approximately", "archaeological",
            "argumentative", "autobiography", "bibliography", "characteristic", "chronological", "circumstances", "classification", "collaboration", "commemorate", "communication"],
        8: ["abbreviation", "acceleration", "accessibility", "accomplishment", "accountability", "acknowledgement", "administration", "alphabetically", "announcements", "archaeological",
            "assassination", "authentication", "autobiography", "biodegradable", "characteristics", "circumference", "classification", "commercialize", "communication", "comprehensive"],
        9: ["accommodation", "accomplishment", "acknowledgment", "administration", "alphabetically", "announcements", "approximately", "archaeological", "authentication", "autobiography",
            "biodegradable", "characteristics", "chronological", "circumference", "classification", "collaboration", "commercialize", "communication", "comprehensive", "confederation"],
        10: ["conscientious", "correspondence", "discrimination", "electromagnetic", "entrepreneurial", "environmental", "fundamentalism", "hallucination", "hospitalization", "hypothetically",
             "identification", "implementation", "impressionable", "incomprehensible", "individualism", "industrialization", "infrastructure", "institutionalize", "instrumentation", "intellectualism"],
        11: ["acknowledgeable", "characterization", "circumstantial", "commercialization", "compartmentalize", "comprehensibility", "conceptualization", "confidentiality", "congratulations", "conscientiously",
             "constitutionality", "contemporaneous", "conventionalize", "correspondence", "counterproductive", "crystallization", "decentralization", "demilitarization", "democratization", "departmentalize"],
        12: ["autobiographical", "characteristically", "compartmentalization", "comprehensively", "conceptualization", "confidentiality", "congratulatory", "conscientiously", "constitutionally", "contemporaneously",
             "conventionally", "correspondingly", "counterproductively", "crystallographic", "decentralization", "demilitarization", "democratization", "departmentalization", "deterministically", "developmentally"]
    ]

    func getWords(grade: Int, level: Int, count: Int) -> [Word] {
        let baseDifficulty = grade
        let levelBonus = (level - 1) / 10
        let difficulty = min(baseDifficulty + levelBonus, 12)

        // Track words with their actual source difficulty
        var availableWords: [(text: String, difficulty: Int)] = []

        for diff in max(1, difficulty - 1)...min(difficulty + 1, 12) {
            if let words = wordsByDifficulty[diff] {
                // Store each word with its actual difficulty
                for word in words {
                    availableWords.append((text: word, difficulty: diff))
                }
            }
        }

        let shuffled = availableWords.shuffled()
        let selected = Array(shuffled.prefix(count))

        // Create Word objects with correct difficulty for each word
        return selected.map { Word(text: $0.text, difficulty: $0.difficulty) }
    }

    func getSentences(for word: Word) -> [WordSentence] {
        return (1...3).map { sentenceNum in
            WordSentence(
                word: word.text,
                difficulty: word.difficulty,
                sentenceNumber: sentenceNum
            )
        }
    }
}
