//
//  WordSentence.swift
//  spelling-bee iOS App
//
//  Data model for word usage in sentences.
//

import Foundation

struct WordSentence: Identifiable {
    let id = UUID()
    let word: String
    let difficulty: Int
    let sentenceNumber: Int  // 1, 2, or 3

    var displayLabel: String {
        "Sentence \(sentenceNumber)"
    }

    var audioPath: String {
        "Audio/Lisa/sentences/difficulty_\(difficulty)/\(word.lowercased())_sentence\(sentenceNumber)"
    }
}
