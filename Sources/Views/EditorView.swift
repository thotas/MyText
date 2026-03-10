import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            FoldGutterView(
                viewModel: viewModel,
                themeManager: themeManager,
                onFoldClick: { line in
                    viewModel.toggleFold(at: line)
                }
            )
            SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
        }
        .background(Color(themeManager.currentTheme.editorBackground))
    }
}

// MARK: - Fold Gutter View

struct FoldGutterView: View {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager
    var onFoldClick: (Int) -> Void

    private let gutterWidth: CGFloat = 24
    private let lineHeight: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.document.content.components(separatedBy: "\n").enumerated()), id: \.offset) { index, _ in
                let lineNumber = index + 1
                FoldIndicatorView(
                    lineNumber: lineNumber,
                    indicator: viewModel.getFoldIndicator(for: lineNumber),
                    isFolded: viewModel.isLineFolded(lineNumber),
                    onTap: { onFoldClick(lineNumber) }
                )
                .frame(height: lineHeight)
            }
        }
        .frame(width: gutterWidth)
        .background(Color(themeManager.currentTheme.gutterBackground))
    }
}

struct FoldIndicatorView: View {
    let lineNumber: Int
    let indicator: EditorViewModel.FoldIndicator?
    let isFolded: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            if let indicator = indicator {
                switch indicator {
                case .collapsed:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .onTapGesture { onTap() }
                case .expanded:
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .onTapGesture { onTap() }
                case .end:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        // Configure invisible characters (show Invisibles) via layoutManager
        textView.layoutManager?.showsInvisibleCharacters = ThemeManager.shared.showInvisibles()

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

        // Update invisible characters setting
        textView.layoutManager?.showsInvisibleCharacters = ThemeManager.shared.showInvisibles()

        // Update word wrap setting
        if viewModel.wordWrap {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(
                width: nsView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        } else {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        }

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
        private var currentLineHighlight: NSRange?
        private var bracketMatchHighlight: NSRange?

        // Bracket pairs: opening -> closing
        private let bracketPairs: [Character: Character] = [
            "(": ")",
            "[": "]",
            "{": "}",
            "<": ">"
        ]

        private let closingBrackets: Set<Character> = [")", "]", "}", ">"]

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

            NotificationCenter.default.addObserver(
                forName: .toggleFold,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.toggleFoldAtCursor()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .foldAll,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.foldAll()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .unfoldAll,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.parent.viewModel.unfoldAll()
                }
            }

            // Refresh editor (for settings changes like showInvisibles)
            NotificationCenter.default.addObserver(
                forName: .refreshEditor,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self,
                      let textView = self.parent.viewModel.textView else { return }
                // Re-apply the showsInvisibleCharacters setting
                textView.layoutManager?.showsInvisibleCharacters = ThemeManager.shared.showInvisibles()
            }
        }

        private func toggleFoldAtCursor() {
            guard let textView = parent.viewModel.textView else { return }
            let cursorPos = textView.selectedRange().location
            let string = textView.string as NSString
            let lineRange = string.lineRange(for: NSRange(location: cursorPos, length: 0))
            let lineNumber = string.substring(to: lineRange.location).components(separatedBy: "\n").count

            parent.viewModel.toggleFold(at: lineNumber)
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

            // Update current line highlight
            highlightCurrentLine(in: textView)

            // Cancel any pending highlight
            highlightWorkItem?.cancel()

            // Schedule highlighting with debounce
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyHighlighting(to: textView)
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            highlightCurrentLine(in: textView)
            highlightMatchingBracket(in: textView)
        }

        // MARK: - Bracket Matching

        private func highlightMatchingBracket(in textView: NSTextView) {
            // Remove old bracket highlight
            if let oldRange = bracketMatchHighlight, oldRange.location != NSNotFound {
                textView.textStorage?.removeAttribute(.underlineStyle, range: oldRange)
                textView.textStorage?.removeAttribute(.underlineColor, range: oldRange)
            }

            let selectedRange = textView.selectedRange()
            guard selectedRange.location > 0 else { return }

            let string = textView.string as NSString
            let charIndex = selectedRange.location - 1
            guard charIndex < string.length else { return }

            let char = Character(UnicodeScalar(string.character(at: charIndex))!)

            // Check if character is a bracket
            if let closingBracket = bracketPairs[char] {
                // Opening bracket - find closing bracket
                if let matchRange = findMatchingBracket(
                    from: charIndex + 1,
                    searchingForward: true,
                    openingBracket: char,
                    closingBracket: closingBracket,
                    in: string
                ) {
                    highlightBracket(in: textView, range: matchRange)
                }
            } else if closingBrackets.contains(char) {
                // Closing bracket - find opening bracket
                if let openingBracket = bracketPairs.first(where: { $0.value == char })?.key {
                    if let matchRange = findMatchingBracket(
                        from: charIndex - 1,
                        searchingForward: false,
                        openingBracket: openingBracket,
                        closingBracket: char,
                        in: string
                    ) {
                        highlightBracket(in: textView, range: matchRange)
                    }
                }
            }
        }

        private func findMatchingBracket(
            from startIndex: Int,
            searchingForward: Bool,
            openingBracket: Character,
            closingBracket: Character,
            in string: NSString
        ) -> NSRange? {
            var depth = 1
            var index = startIndex

            while index >= 0 && index < string.length {
                let currentChar = Character(UnicodeScalar(string.character(at: index))!)

                if searchingForward {
                    if currentChar == openingBracket {
                        depth += 1
                    } else if currentChar == closingBracket {
                        depth -= 1
                        if depth == 0 {
                            return NSRange(location: index, length: 1)
                        }
                    }
                    index += 1
                } else {
                    if currentChar == closingBracket {
                        depth += 1
                    } else if currentChar == openingBracket {
                        depth -= 1
                        if depth == 0 {
                            return NSRange(location: index, length: 1)
                        }
                    }
                    index -= 1
                }
            }

            return nil
        }

        private func highlightBracket(in textView: NSTextView, range: NSRange) {
            textView.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            textView.textStorage?.addAttribute(.underlineColor, value: NSColor.systemYellow, range: range)
            bracketMatchHighlight = range
        }

        private func highlightCurrentLine(in textView: NSTextView) {
            // Remove old highlight
            if let oldRange = currentLineHighlight, oldRange.location != NSNotFound {
                textView.textStorage?.removeAttribute(.backgroundColor, range: oldRange)
            }

            // Get current line range
            let selectedRange = textView.selectedRange()
            let string = textView.string as NSString
            let lineRange = string.lineRange(for: NSRange(location: selectedRange.location, length: 0))

            guard lineRange.length > 0 else { return }

            // Add new highlight
            let highlightColor = NSColor(Color(parent.themeManager.currentTheme.currentLineBackground))
            textView.textStorage?.addAttribute(.backgroundColor, value: highlightColor, range: lineRange)
            currentLineHighlight = lineRange
        }

        func applyHighlighting(to textView: NSTextView) {
            let language = parent.viewModel.detectedLanguage
            let contentHash = textView.string.hashValue

            // Skip if nothing changed
            guard language != lastAppliedLanguage || contentHash != lastContentHash else { return }

            lastAppliedLanguage = language
            lastContentHash = contentHash

            // Detect fold regions
            parent.viewModel.detectFoldRegions()

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

            // Apply fold styling to folded lines
            applyFoldStyling(to: textView)

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
            let selectedRange = textView.selectedRange()
            let string = textView.string as NSString
            let lineRange = string.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            return string.substring(with: lineRange)
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

        // MARK: - Fold Styling

        private func applyFoldStyling(to textView: NSTextView) {
            let content = textView.string
            let lines = content.components(separatedBy: "\n")

            for region in parent.viewModel.foldRegions where region.isFolded {
                // Apply styling to folded lines (lines between start and end)
                for lineIndex in (region.startLine)..<region.endLine {
                    guard lineIndex < lines.count else { continue }

                    let lineStart = lines[0..<lineIndex].map { $0.count + 1 }.reduce(0, +)
                    let lineLength = lines[lineIndex].count

                    if lineLength > 0 {
                        let range = NSRange(location: lineStart, length: lineLength)
                        // Add subtle background to indicate folded region
                        let foldColor = NSColor.secondaryLabelColor.withAlphaComponent(0.1)
                        textView.textStorage?.addAttribute(.backgroundColor, value: foldColor, range: range)
                    }
                }

                // Add ellipsis indicator at the start line
                if region.startLine <= lines.count {
                    let lineStart = lines[0..<(region.startLine - 1)].map { $0.count + 1 }.reduce(0, +)
                    let lineLength = lines[region.startLine - 1].count
                    if lineLength > 0 {
                        let range = NSRange(location: lineStart, length: lineLength)
                        // Can add a marker or styling here
                    }
                }
            }
        }
    }
}
