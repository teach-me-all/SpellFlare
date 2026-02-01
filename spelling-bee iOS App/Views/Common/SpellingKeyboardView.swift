//
//  SpellingKeyboardView.swift
//  spelling-bee iOS App
//
//  Custom QWERTY keyboard for spelling mode. Replaces the system keyboard
//  to prevent predictive text, autocorrect, and word suggestions.
//  Provides large, kid-friendly tap targets.
//

import UIKit

// MARK: - Delegate Protocol

protocol SpellingKeyboardDelegate: AnyObject {
    func keyboardDidTapLetter(_ letter: String)
    func keyboardDidTapBackspace()
    func keyboardDidTapDone()
}

// MARK: - SpellingKeyboardView

final class SpellingKeyboardView: UIView {

    weak var delegate: SpellingKeyboardDelegate?

    // Layout constants
    private let keyHeight: CGFloat = 48
    private let horizontalSpacing: CGFloat = 6
    private let verticalSpacing: CGFloat = 8
    private let keyCornerRadius: CGFloat = 8
    private let sidePadding: CGFloat = 4

    // QWERTY rows
    private let row1 = ["Q","W","E","R","T","Y","U","I","O","P"]
    private let row2 = ["A","S","D","F","G","H","J","K","L"]
    private let row3 = ["Z","X","C","V","B","N","M"]

    // Colors (defaults, updated via applyTheme)
    private var keyBackgroundColor = UIColor.white.withAlphaComponent(0.25)
    private var keyTextColor = UIColor.white
    private var accentColor = UIColor.cyan
    private var bgColor = UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)

    // Containers
    private let stackView = UIStackView()
    private var allKeyButtons: [UIButton] = []
    private var backspaceButton: UIButton?
    private var doneButton: UIButton?

    // MARK: - Init

    init() {
        let screenWidth = UIScreen.main.bounds.width
        super.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 260))
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupKeyboard()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupKeyboard()
    }

    // MARK: - Intrinsic Size

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 260)
    }

    // MARK: - Theme

    func applyTheme(_ themeID: String?) {
        let colors = ThemeKeyboardColors.colors(for: themeID)
        bgColor = colors.background
        keyBackgroundColor = colors.keyBackground
        keyTextColor = colors.keyText
        accentColor = colors.accent
        applyCurrentColors()
    }

    private func applyCurrentColors() {
        backgroundColor = bgColor

        for btn in allKeyButtons {
            btn.backgroundColor = keyBackgroundColor
            btn.setTitleColor(keyTextColor, for: .normal)
        }

        if let bs = backspaceButton {
            bs.backgroundColor = keyBackgroundColor
            bs.tintColor = keyTextColor
        }

        if let done = doneButton {
            done.backgroundColor = accentColor
            done.setTitleColor(.white, for: .normal)
        }
    }

    // MARK: - Layout

    private func setupKeyboard() {
        backgroundColor = bgColor

        stackView.axis = .vertical
        stackView.spacing = verticalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePadding),
        ])

        // Row 1: Q-P
        let r1 = makeLetterRow(row1)
        stackView.addArrangedSubview(r1)
        r1.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // Row 2: A-L (indented by half-key width)
        let r2 = makeLetterRow(row2)
        stackView.addArrangedSubview(r2)
        r2.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.92).isActive = true

        // Row 3: Z-M + Backspace
        let r3 = makeRow3WithBackspace()
        stackView.addArrangedSubview(r3)
        r3.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // Row 4: Done button
        let r4 = makeDoneRow()
        stackView.addArrangedSubview(r4)
        r4.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.45).isActive = true
    }

    // MARK: - Row Builders

    private func makeLetterRow(_ letters: [String]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = horizontalSpacing
        row.distribution = .fillEqually

        for letter in letters {
            let btn = makeKeyButton(title: letter)
            btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
            btn.accessibilityLabel = letter
            btn.accessibilityTraits = .keyboardKey
            row.addArrangedSubview(btn)
            allKeyButtons.append(btn)
        }
        row.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
        return row
    }

    private func makeRow3WithBackspace() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = horizontalSpacing
        row.distribution = .fill

        // Spacer on left to center letters
        let leftSpacer = UIView()
        leftSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(leftSpacer)

        // Letter keys
        let lettersStack = UIStackView()
        lettersStack.axis = .horizontal
        lettersStack.spacing = horizontalSpacing
        lettersStack.distribution = .fillEqually

        for letter in row3 {
            let btn = makeKeyButton(title: letter)
            btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
            btn.accessibilityLabel = letter
            btn.accessibilityTraits = .keyboardKey
            lettersStack.addArrangedSubview(btn)
            allKeyButtons.append(btn)
        }
        row.addArrangedSubview(lettersStack)

        // Backspace button (1.5x key width)
        let bs = UIButton(type: .system)
        bs.setImage(UIImage(systemName: "delete.backward"), for: .normal)
        bs.tintColor = keyTextColor
        bs.backgroundColor = keyBackgroundColor
        bs.layer.cornerRadius = keyCornerRadius
        bs.clipsToBounds = true
        bs.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        bs.accessibilityLabel = "Delete"
        bs.accessibilityTraits = .keyboardKey
        addTapAnimation(to: bs)
        row.addArrangedSubview(bs)
        backspaceButton = bs

        // Set width relationships
        // Each letter key should be equal width; backspace 1.5x of one letter key
        if let firstLetterBtn = lettersStack.arrangedSubviews.first {
            bs.widthAnchor.constraint(equalTo: firstLetterBtn.widthAnchor, multiplier: 1.5).isActive = true
        }
        leftSpacer.widthAnchor.constraint(equalTo: bs.widthAnchor, multiplier: 0.35).isActive = true

        row.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
        return row
    }

    private func makeDoneRow() -> UIView {
        let container = UIView()
        let btn = UIButton(type: .system)
        btn.setTitle("DONE", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = accentColor
        btn.layer.cornerRadius = keyCornerRadius
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        btn.accessibilityLabel = "Done"
        btn.accessibilityTraits = .keyboardKey
        addTapAnimation(to: btn)

        btn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        container.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
        doneButton = btn
        return container
    }

    private func makeKeyButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        btn.setTitleColor(keyTextColor, for: .normal)
        btn.backgroundColor = keyBackgroundColor
        btn.layer.cornerRadius = keyCornerRadius
        btn.clipsToBounds = true
        addTapAnimation(to: btn)
        return btn
    }

    // MARK: - Tap Animation

    private func addTapAnimation(to button: UIButton) {
        button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func keyTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
    }

    @objc private func keyTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3) {
            sender.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func letterTapped(_ sender: UIButton) {
        guard let letter = sender.title(for: .normal) else { return }
        delegate?.keyboardDidTapLetter(letter)
    }

    @objc private func backspaceTapped() {
        delegate?.keyboardDidTapBackspace()
    }

    @objc private func doneTapped() {
        delegate?.keyboardDidTapDone()
    }
}

// MARK: - Theme Color Helper (bridges SwiftUI ThemeService to UIKit)

enum ThemeKeyboardColors {
    struct Colors {
        let background: UIColor
        let keyBackground: UIColor
        let keyText: UIColor
        let accent: UIColor
    }

    static func colors(for themeID: String?) -> Colors {
        // Derive keyboard background from the darkest gradient color of each theme
        switch themeID {
        case "bg_space":
            return Colors(
                background: UIColor(red: 0.05, green: 0.05, blue: 0.2, alpha: 1.0),
                keyBackground: UIColor.white.withAlphaComponent(0.2),
                keyText: .white,
                accent: .cyan
            )
        case "bg_ocean":
            return Colors(
                background: UIColor(red: 0.0, green: 0.25, blue: 0.5, alpha: 1.0),
                keyBackground: UIColor.white.withAlphaComponent(0.25),
                keyText: .white,
                accent: .cyan
            )
        case "bg_candy":
            return Colors(
                background: UIColor(red: 0.75, green: 0.25, blue: 0.45, alpha: 1.0),
                keyBackground: UIColor.white.withAlphaComponent(0.25),
                keyText: .white,
                accent: UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
            )
        case "bg_forest":
            return Colors(
                background: UIColor(red: 0.08, green: 0.3, blue: 0.15, alpha: 1.0),
                keyBackground: UIColor.white.withAlphaComponent(0.25),
                keyText: .white,
                accent: UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1.0)
            )
        default:
            // Default purple theme
            return Colors(
                background: UIColor(red: 0.3, green: 0.15, blue: 0.7, alpha: 1.0),
                keyBackground: UIColor.white.withAlphaComponent(0.25),
                keyText: .white,
                accent: .cyan
            )
        }
    }
}
