import SwiftUI
import AppKit

struct FindBarView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Binding var isPresented: Bool
    var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var caseSensitive = false
    @State private var useRegex = false

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(themeManager.currentTheme.comment))

                TextField("Find", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Color(themeManager.currentTheme.text))
                    .onSubmit {
                        findNext()
                    }

                if !searchText.isEmpty {
                    Text("\(findCount) matches")
                        .font(.system(size: 11))
                        .foregroundColor(Color(themeManager.currentTheme.comment))
                }

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Options
                Toggle("Case Sensitive", isOn: $caseSensitive)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundColor(Color(themeManager.currentTheme.text))

                Toggle("Regex", isOn: $useRegex)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundColor(Color(themeManager.currentTheme.text))

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Navigation buttons
                Button(action: findPrevious) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))

                Button(action: findNext) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Close button
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.comment))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(themeManager.currentTheme.toolbar))
        }
        .frame(height: 40)
    }

    private var findCount: Int {
        guard !searchText.isEmpty else { return 0 }
        let text = viewModel.document.content
        let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive

        var count = 0
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: searchText, options: options, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }

        return count
    }

    private func findNext() {
        performSearch(forward: true)
    }

    private func findPrevious() {
        performSearch(forward: false)
    }

    private func performSearch(forward: Bool) {
        guard !searchText.isEmpty else { return }

        let text = viewModel.document.content
        let currentPos = viewModel.editorState.cursorPosition

        var options: String.CompareOptions = forward ? [] : .backwards
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }

        if let range = text.range(of: searchText, options: options, range: forward ? text.index(text.startIndex, offsetBy: min(currentPos + 1, text.count))..<text.endIndex : text.startIndex..<text.index(text.startIndex, offsetBy: max(0, currentPos - 1))) {
            let pos = text.distance(from: text.startIndex, to: range.lowerBound)
            viewModel.editorState.cursorPosition = pos
        } else {
            // Wrap around
            if let range = text.range(of: searchText, options: options) {
                let pos = text.distance(from: text.startIndex, to: range.lowerBound)
                viewModel.editorState.cursorPosition = pos
            }
        }
    }
}
