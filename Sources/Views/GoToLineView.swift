import SwiftUI

struct GoToLineView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: EditorViewModel
    @ObservedObject var themeManager: ThemeManager
    @State private var lineNumber: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var totalLines: Int {
        viewModel.document.content.components(separatedBy: "\n").count
    }

    private var isValidLine: Bool {
        guard let num = Int(lineNumber) else { return false }
        return num >= 1 && num <= totalLines
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Go to Line")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(themeManager.currentTheme.text))
                Spacer()
            }
            .padding(12)

            Divider()

            // Input field
            HStack {
                Text("Line number:")
                    .font(.system(size: 13))
                    .foregroundColor(Color(themeManager.currentTheme.text))

                TextField("1-\(totalLines)", text: $lineNumber)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .frame(width: 80)
                    .focused($isTextFieldFocused)

                Text("of \(totalLines)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(themeManager.currentTheme.comment))
            }
            .padding(12)
            .background(Color(themeManager.currentTheme.editorBackground))

            Divider()

            // Buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Go") {
                    goToLine()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidLine)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(12)
        }
        .frame(width: 300)
        .background(Color(themeManager.currentTheme.background))
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func goToLine() {
        guard let lineNum = Int(lineNumber), lineNum >= 1, lineNum <= totalLines else { return }

        let lines = viewModel.document.content.components(separatedBy: "\n")
        var charIndex = 0

        for i in 0..<(lineNum - 1) {
            charIndex += lines[i].count + 1 // +1 for newline
        }

        // Navigate to the line in the text view
        if let textView = viewModel.textView {
            let range = NSRange(location: charIndex, length: 0)
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }

        isPresented = false
    }
}
