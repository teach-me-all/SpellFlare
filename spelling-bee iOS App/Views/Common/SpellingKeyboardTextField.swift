//
//  SpellingKeyboardTextField.swift
//  spelling-bee iOS App
//
//  SwiftUI bridge wrapping a UITextField with the custom SpellingKeyboardView
//  as its inputView. Blocks paste/autocorrect and filters input to letters only.
//

import SwiftUI
import UIKit

struct SpellingKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    var isFirstResponder: Bool
    var onDone: () -> Void
    var themeID: String?

    func makeUIView(context: Context) -> NoPasteTextField {
        let textField = NoPasteTextField()

        // Disable all system text assistance
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .allCharacters
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no

        // Remove suggestion bar
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []

        // Visual styling — the text field itself is mostly a data conduit;
        // the visible "input area" is styled in SwiftUI around this view.
        textField.font = .monospacedSystemFont(ofSize: 24, weight: .medium)
        textField.textAlignment = .center
        textField.textColor = .label
        textField.tintColor = .cyan
        textField.backgroundColor = .clear
        textField.borderStyle = .none

        // Set up custom keyboard
        let keyboard = SpellingKeyboardView()
        keyboard.delegate = context.coordinator
        keyboard.applyTheme(themeID)
        textField.inputView = keyboard

        // Delegate & text change observation
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)

        context.coordinator.textField = textField

        return textField
    }

    func updateUIView(_ textField: NoPasteTextField, context: Context) {
        // Sync text from binding → UIKit (avoid feedback loop)
        if textField.text != text {
            textField.text = text
        }

        // Update theme if changed
        if let keyboard = textField.inputView as? SpellingKeyboardView {
            keyboard.applyTheme(themeID)
        }

        // Manage first responder
        if isFirstResponder && !textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.reloadInputViews()
                textField.becomeFirstResponder()
            }
        } else if !isFirstResponder && textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextFieldDelegate, SpellingKeyboardDelegate {
        var parent: SpellingKeyboardTextField
        weak var textField: NoPasteTextField?

        init(_ parent: SpellingKeyboardTextField) {
            self.parent = parent
        }

        // MARK: SpellingKeyboardDelegate

        func keyboardDidTapLetter(_ letter: String) {
            guard let tf = textField else { return }
            tf.insertText(letter)
        }

        func keyboardDidTapBackspace() {
            guard let tf = textField else { return }
            tf.deleteBackward()
        }

        func keyboardDidTapDone() {
            parent.onDone()
        }

        // MARK: UITextFieldDelegate — filter hardware keyboard input

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow deletions
            if string.isEmpty { return true }

            // Only allow letters (filters out numbers, symbols, etc.)
            let lettersOnly = string.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
            if lettersOnly {
                // Force uppercase
                let upper = string.uppercased()
                if upper != string {
                    // Insert uppercase version manually
                    if let tf = self.textField,
                       let textRange = Range(range, in: tf.text ?? "") {
                        let newText = (tf.text ?? "").replacingCharacters(in: textRange, with: upper)
                        tf.text = newText
                        parent.text = newText
                        return false
                    }
                }
                return true
            }
            return false
        }

        // MARK: Text sync

        @objc func textChanged(_ sender: UITextField) {
            let newText = sender.text ?? ""
            if parent.text != newText {
                parent.text = newText
            }
        }
    }
}

// MARK: - NoPasteTextField

/// UITextField subclass that blocks copy, paste, cut, select, and selectAll.
final class NoPasteTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)),
             #selector(UIResponderStandardEditActions.cut(_:)),
             #selector(UIResponderStandardEditActions.select(_:)),
             #selector(UIResponderStandardEditActions.selectAll(_:)),
             #selector(UIResponderStandardEditActions.copy(_:)):
            return false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
}
