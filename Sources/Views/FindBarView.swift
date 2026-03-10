import SwiftUI
import AppKit

struct FindBarView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Binding var isPresented: Bool
    var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var caseSensitive = false
    @State private var useRegex = false

    var body: some View {
        VStack(spacing: 0) {
            // Search field row
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(themeManager.currentTheme.comment))

                TextField("Find", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Color(themeManager.currentTheme.text))
                    .onSubmit {
                        viewModel.findNext(searchText: searchText, isRegex: useRegex)
                    }
                    .onChange(of: searchText) { _ in
                        highlightMatches()
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
                    .onChange(of: caseSensitive) { _ in
                        highlightMatches()
                    }

                Toggle("Regex", isOn: $useRegex)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundColor(Color(themeManager.currentTheme.text))

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Navigation buttons with keyboard shortcuts
                Button(action: { viewModel.findPrevious(searchText: searchText, isRegex: useRegex) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button(action: { viewModel.findNext(searchText: searchText, isRegex: useRegex) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))
                .keyboardShortcut("g", modifiers: .command)

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Close button
                Button(action: {
                    viewModel.clearMatchHighlights()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.comment))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Replace field row
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(Color(themeManager.currentTheme.comment))

                TextField("Replace", text: $replaceText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Color(themeManager.currentTheme.text))

                Rectangle()
                    .fill(Color(themeManager.currentTheme.lineNumber).opacity(0.3))
                    .frame(width: 1, height: 20)

                // Replace buttons
                Button(action: replaceNext) {
                    Text("Replace")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))
                .disabled(searchText.isEmpty || replaceText.isEmpty)

                Button(action: replaceAll) {
                    Text("Replace All")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(themeManager.currentTheme.text))
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(searchText.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(themeManager.currentTheme.toolbar).opacity(0.9))
        }
        .background(Color(themeManager.currentTheme.toolbar))
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

    private func highlightMatches() {
        if searchText.isEmpty {
            viewModel.clearMatchHighlights()
        } else {
            viewModel.highlightMatches(searchText)
        }
    }

    private func replaceNext() {
        viewModel.replaceNext(searchText: searchText, replaceWith: replaceText)
        highlightMatches()
    }

    private func replaceAll() {
        viewModel.replaceAll(searchText: searchText, replaceWith: replaceText)
    }
}
