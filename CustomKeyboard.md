Claude Implementation Prompt — Custom Spelling Keyboard (No Word Suggestions)

You are implementing a custom in-app keyboard for a children’s spelling game in an iOS + watchOS companion app.

The goal is to prevent iOS keyboard word suggestions, autocorrect, and predictive help during spelling challenges.

This keyboard is only used during Level / Spelling Mode, not in menus or profile screens.

🎯 Objectives

Replace the system keyboard with a custom letter-only keyboard

Prevent:

Predictive text bar

Autocorrect

Spell check

Paste assistance

Keep the experience simple, fun, and kid-friendly

Work on iPhone first, with architecture compatible for future Watch adaptation

📱 iPhone Requirements
1️⃣ Custom Input View

Attach a custom keyboard view to the spelling answer field.

textField.inputView = SpellingKeyboardView()


Disable all smart typing features:

textField.autocorrectionType = .no
textField.spellCheckingType = .no
textField.autocapitalizationType = .none
textField.smartQuotesType = .no
textField.smartDashesType = .no
textField.smartInsertDeleteType = .no
textField.textContentType = .oneTimeCode

⌨️ SpellingKeyboardView

Create a reusable component:

class SpellingKeyboardView: UIView

Layout

Grid of A–Z letter buttons

One Backspace key

One Done / Submit key

Suggested layout:

Q W E R T Y U I O P
A S D F G H J K L
Z X C V B N M ⌫
          DONE

Behavior

Tapping a letter inserts it into the active text field

Backspace deletes one character

Done triggers delegate callback

Use a delegate protocol:

protocol SpellingKeyboardDelegate: AnyObject {
    func didTapLetter(_ letter: String)
    func didTapBackspace()
    func didTapDone()
}

🔒 Input Restrictions

During spelling mode:

Disable copy/paste menu

override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
}


Maximum characters should match word length if available

Input must be uppercase only

🎨 Visual Style

The keyboard should be:

Bright and playful

Large tap targets for kids

Rounded buttons

Subtle animations on tap (scale down then up)

Compatible with future theming (bee skins)

Do not hardcode colors — use theme variables.

🧩 Integration

In Level View:

Replace normal text field keyboard with custom one

Keep normal keyboard everywhere else in the app

When level ends, restore default keyboard behavior

🧪 Edge Cases

Hardware keyboard input should still be accepted

If keyboard fails to load, fallback to system keyboard with autocorrect OFF

Ensure VoiceOver still reads letters correctly

✅ Acceptance Criteria

✔ No predictive bar visible
✔ No autocorrect corrections
✔ No word suggestions
✔ Kids must tap each letter manually
✔ Works smoothly on all supported iPhones

Structure the code to be modular and reusable for future watchOS letter input UI.
