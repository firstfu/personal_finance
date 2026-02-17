import SwiftUI

enum NumberPadLogic {
    static func append(_ char: String, to text: inout String) {
        if char == "." {
            guard !text.contains(".") else { return }
            if text.isEmpty { text = "0" }
            text.append(".")
            return
        }

        if let dotIndex = text.firstIndex(of: ".") {
            let decimalPart = text[text.index(after: dotIndex)...]
            guard decimalPart.count < 2 else { return }
        }

        if text == "0" {
            text = char
            return
        }

        let candidate = text + char
        let integerPart = candidate.split(separator: ".").first.map(String.init) ?? candidate
        guard integerPart.count <= 7 else { return }

        text.append(char)
    }

    static func deleteLast(from text: inout String) {
        guard !text.isEmpty else { return }
        text.removeLast()
    }

    static func formatted(_ text: String) -> String {
        guard !text.isEmpty else { return "0" }

        let parts = text.split(separator: ".", maxSplits: 1)
        let integerPart = String(parts[0])

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","

        let formatted: String
        if let number = Int(integerPart) {
            formatted = formatter.string(from: NSNumber(value: number)) ?? integerPart
        } else {
            formatted = integerPart
        }

        if parts.count > 1 {
            return formatted + "." + parts[1]
        } else if text.hasSuffix(".") {
            return formatted + "."
        }
        return formatted
    }
}

struct NumberPadView: View {
    @Binding var text: String
    var onSave: () -> Void
    var canSave: Bool

    private let buttons: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        NumberPadButton(key: key) {
                            handleTap(key)
                        } onLongPress: {
                            if key == "⌫" {
                                NumberPadLogic.deleteLast(from: &text)
                            }
                        }
                    }
                }
            }

            Button(action: onSave) {
                Text("儲存")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? AppTheme.primaryDark : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            }
            .disabled(!canSave)
            .padding(.top, 4)
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
    }

    private func handleTap(_ key: String) {
        if key == "⌫" {
            NumberPadLogic.deleteLast(from: &text)
        } else {
            NumberPadLogic.append(key, to: &text)
        }
    }
}

struct NumberPadButton: View {
    let key: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var longPressTimer: Timer?

    var body: some View {
        Text(key == "⌫" ? "" : key)
            .font(.title2.weight(.medium))
            .overlay {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            .opacity(isPressed ? 0.7 : 1.0)
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                isPressed = pressing
                if pressing && key == "⌫" {
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        onLongPress()
                    }
                } else {
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                }
            }, perform: {})
    }
}
