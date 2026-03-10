import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            // Cursor position
            HStack(spacing: 4) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 10))
                Text("Ln \(viewModel.editorState.lineNumber), Col \(viewModel.editorState.columnNumber)")
            }
            .foregroundStyle(Color(themeManager.currentTheme.comment))

            Rectangle()
                .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                .frame(width: 1, height: 12)

            // Language
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10))
                Text(viewModel.detectedLanguage.displayName)
            }
            .foregroundStyle(Color(themeManager.currentTheme.comment))

            Rectangle()
                .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                .frame(width: 1, height: 12)

            // Encoding
            Text("UTF-8")
                .foregroundStyle(Color(themeManager.currentTheme.comment))

            Rectangle()
                .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                .frame(width: 1, height: 12)

            // Line ending
            Text(TextDocument.LineEnding.unix.displayName)
                .foregroundStyle(Color(themeManager.currentTheme.comment))

            Rectangle()
                .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                .frame(width: 1, height: 12)

            // Word wrap toggle
            Button(action: {
                viewModel.toggleWordWrap()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.wordWrap ? "text.alignleft" : "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundStyle(viewModel.wordWrap ? Color.blue : Color(themeManager.currentTheme.comment))
                    Text("Wrap")
                        .foregroundStyle(viewModel.wordWrap ? Color.blue : Color(themeManager.currentTheme.comment))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Modified indicator
            if viewModel.document.isModified {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("Modified")
                }
                .foregroundStyle(Color(themeManager.currentTheme.comment))
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(errorMessage)
                }
                .foregroundStyle(Color.red)
            }
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(themeManager.currentTheme.toolbar))
    }
}
