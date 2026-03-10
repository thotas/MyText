import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    var body: some View {
        SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
            .background(Color(themeManager.currentTheme.editorBackground))
    }
}

struct SimpleTextEditor: NSViewRepresentable {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFontPanel = false

        // Disable auto substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false

        // Configure appearance
        textView.backgroundColor = NSColor(Color(themeManager.currentTheme.editorBackground))
        textView.insertionPointColor = NSColor(Color(themeManager.currentTheme.cursor))
        textView.textColor = NSColor(Color(themeManager.currentTheme.text))

        // Configure font
        let fontSize = ThemeManager.shared.fontSize()
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Configure layout
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Set initial content
        textView.string = viewModel.document.content

        // Set delegate
        textView.delegate = context.coordinator

        // Set textView reference for line operations
        viewModel.setTextView(textView)

        // Apply initial highlighting
        context.coordinator.applyHighlighting(to: textView)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Update appearance based on theme
        textView.backgroundColor = NSColor(Color(themeManager.currentTheme.editorBackground))
        textView.insertionPointColor = NSColor(Color(themeManager.currentTheme.cursor))

        // Update font
        let fontSize = ThemeManager.shared.fontSize()
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Check if content changed or language changed
        let contentChanged = textView.string != viewModel.document.content

        if contentChanged {
            textView.string = viewModel.document.content
            // Re-apply highlighting when file is loaded
            context.coordinator.applyHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor
        private var highlightWorkItem: DispatchWorkItem?
        private var lastAppliedLanguage: ProgrammingLanguage = .plainText
        private var lastContentHash: Int = 0

        init(_ parent: SimpleTextEditor) {
            self.parent = parent
            super.init()
            setupNotificationObservers()
        }

        private func setupNotificationObservers() {
            NotificationCenter.default.addObserver(
                forName: .duplicateLine,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.duplicateLine()
                    self.reapplyHighlighting()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .moveLineUp,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.moveLineUp()
                    self.reapplyHighlighting()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .moveLineDown,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.moveLineDown()
                    self.reapplyHighlighting()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .toggleComment,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.toggleComment()
                    self.reapplyHighlighting()
                }
            }
        }

        private func reapplyHighlighting() {
            guard let textView = parent.viewModel.textView else { return }
            let language = parent.viewModel.detectedLanguage
            let theme = parent.viewModel.themeManager.currentTheme

            parent.viewModel.syntaxHighlighter.highlightAsync(
                parent.viewModel.document.content,
                language: language,
                theme: theme
            ) { [weak self] highlighted in
                guard let textView = self?.parent.viewModel.textView,
                      let storage = textView.textStorage else { return }
                let selectedRange = textView.selectedRange()
                storage.setAttributedString(highlighted)
                textView.setSelectedRange(selectedRange)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update document
            parent.viewModel.updateContent(textView.string)

            // Cancel any pending highlight
            highlightWorkItem?.cancel()

            // Schedule highlighting with debounce
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyHighlighting(to: textView)
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        func applyHighlighting(to textView: NSTextView) {
            let language = parent.viewModel.detectedLanguage
            let contentHash = textView.string.hashValue

            // Skip if nothing changed
            guard language != lastAppliedLanguage || contentHash != lastContentHash else { return }

            lastAppliedLanguage = language
            lastContentHash = contentHash

            // Skip highlighting for plain text
            guard language != .plainText else { return }

            let theme = parent.themeManager.currentTheme

            // Get highlighted text
            let highlighted = parent.viewModel.syntaxHighlighter.highlight(
                textView.string,
                language: language,
                theme: theme
            )

            // Preserve selection
            let selectedRange = textView.selectedRange()

            // Apply highlighting
            textView.textStorage?.setAttributedString(highlighted)

            // Restore selection
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // MARK: - Auto-Indent

        func textView(_ textView: NSTextView, shouldInsertText string: String, replacingRangeCharRange charRange: NSRange) -> Bool {
            if string == "\n" {
                let currentLine = getCurrentLine(textView: textView)
                let indent = getIndentation(of: currentLine)

                var extraIndent = ""
                let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
                if trimmed.hasSuffix(":") || trimmed.hasSuffix("{") || trimmed.hasSuffix("=") {
                    extraIndent = String(repeating: " ", count: parent.viewModel.tabWidth)
                }

                let insertion = "\n" + indent + extraIndent
                textView.insertText(insertion, replacementRange: charRange)
                return false
            }
            return true
        }

        private func getCurrentLine(textView: NSTextView) -> String {
            let content = textView.string as NSString
            let cursorPosition = textView.selectedRange().location

            // Find the start of the current line
            var lineStart = cursorPosition
            while lineStart > 0 && content.character(at: lineStart - 1) != 0x0A { // 0x0A is newline
                lineStart -= 1
            }

            // Find the end of the current line
            var lineEnd = cursorPosition
            while lineEnd < content.length && content.character(at: lineEnd) != 0x0A {
                lineEnd += 1
            }

            let range = NSRange(location: lineStart, length: lineEnd - lineStart)
            return content.substring(with: range)
        }

        private func getIndentation(of line: String) -> String {
            var indent = ""
            for char in line {
                if char == " " || char == "\t" {
                    indent.append(char)
                } else {
                    break
                }
            }
            return indent
        }
    }
}
