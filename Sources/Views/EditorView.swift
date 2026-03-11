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

        // Add line length guide overlay
        let lineLengthGuide = LineLengthGuideView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        lineLengthGuide.autoresizingMask = [.width, .height]
        scrollView.addSubview(lineLengthGuide)

        // Store reference for updates
        context.coordinator.lineLengthGuideView = lineLengthGuide

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
            // Re-apply highlighting when content changes
            context.coordinator.applyHighlighting(to: textView)
        }

        // Also check if language changed - need to re-apply highlighting
        let languageChanged = context.coordinator.lastAppliedLanguage != viewModel.detectedLanguage
        if languageChanged {
            context.coordinator.applyHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor
        private var highlightWorkItem: DispatchWorkItem?
        var lastAppliedLanguage: ProgrammingLanguage = .plainText
        private var lastContentHash: Int = 0
        private var currentLineHighlight: NSRange?
        private var bracketMatchHighlight: NSRange?
        private var selectionHighlightRanges: [NSRange] = []
        var lineLengthGuideView: LineLengthGuideView?

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
                // Refresh line length guide
                self.lineLengthGuideView?.needsDisplay = true
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

            // Clear selection highlights when text changes
            for range in selectionHighlightRanges {
                textView.textStorage?.removeAttribute(.backgroundColor, range: range)
            }
            selectionHighlightRanges.removeAll()

            // Update current line highlight
            highlightCurrentLine(in: textView)

            // Cancel any pending highlight
            highlightWorkItem?.cancel()

            // Use incremental highlighting for better performance
            // This only re-highlights the affected line(s) instead of the entire document
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyIncrementalHighlighting(to: textView)
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        }

        /// Incremental highlighting - only re-highlights the changed line(s)
        private func applyIncrementalHighlighting(to textView: NSTextView) {
            let language = parent.viewModel.detectedLanguage

            // Skip for plain text
            guard language != .plainText else { return }

            let theme = parent.themeManager.currentTheme
            guard let textStorage = textView.textStorage else { return }

            // Get the current cursor position and find the line range
            let cursorPosition = textView.selectedRange().location
            let string = textView.string as NSString

            // Get the line range at cursor position
            let lineRange = string.lineRange(for: NSRange(location: cursorPosition, length: 0))

            // Use the SyntaxHighlighter's incremental highlight method
            parent.viewModel.syntaxHighlighter.applyIncrementalHighlight(
                to: textStorage,
                text: textView.string,
                lineRange: lineRange,
                language: language,
                theme: theme
            )

            // Re-apply trailing whitespace highlighting for this line
            applyTrailingWhitespaceHighlighting(to: textView, lineRange: lineRange)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            highlightCurrentLine(in: textView)
            highlightMatchingBracket(in: textView)
            highlightSelectedText(in: textView)
        }

        // MARK: - Selection Highlighting

        private func highlightSelectedText(in textView: NSTextView) {
            // Remove old selection highlights
            for range in selectionHighlightRanges {
                textView.textStorage?.removeAttribute(.backgroundColor, range: range)
            }
            selectionHighlightRanges.removeAll()

            // Get selected text
            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else { return }

            let string = textView.string as NSString
            guard selectedRange.location < string.length else { return }

            let selectedText = string.substring(with: selectedRange).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !selectedText.isEmpty, selectedText.count >= 2 else { return }

            // Find all occurrences
            let fullRange = NSRange(location: 0, length: string.length)
            var searchRange = fullRange
            var foundCount = 0
            let maxHighlights = 100 // Limit to prevent performance issues

            // Use case-insensitive search
            while foundCount < maxHighlights {
                let searchString = string.substring(with: searchRange)
                guard let range = searchString.range(of: selectedText, options: .caseInsensitive) else {
                    break
                }

                // Calculate absolute position
                let relativeStart = searchString.distance(from: searchString.startIndex, to: range.lowerBound)
                let absoluteStart = searchRange.location + relativeStart
                let highlightRange = NSRange(location: absoluteStart, length: selectedText.count)

                // Don't highlight the original selection
                if highlightRange != selectedRange {
                    // Use a subtle yellow background for other occurrences
                    let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)
                    textView.textStorage?.addAttribute(.backgroundColor, value: highlightColor, range: highlightRange)
                    selectionHighlightRanges.append(highlightRange)
                    foundCount += 1
                }

                // Move search range forward
                let nextStart = searchRange.location + relativeStart + selectedText.count
                if nextStart >= string.length {
                    break
                }
                searchRange = NSRange(location: nextStart, length: string.length - nextStart)
            }
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

        /// Jump cursor to matching bracket
        func jumpToMatchingBracket() {
            guard let textView = parent.viewModel.textView else { return }

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
                    textView.setSelectedRange(matchRange)
                    textView.scrollRangeToVisible(matchRange)
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
                        textView.setSelectedRange(matchRange)
                        textView.scrollRangeToVisible(matchRange)
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

            // Apply trailing whitespace highlighting
            applyTrailingWhitespaceHighlighting(to: textView)

            // Restore selection
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // MARK: - Auto-Indent

        func textView(_ textView: NSTextView, shouldInsertText string: String, replacingRangeCharRange charRange: NSRange) -> Bool {
            // Handle auto-pair brackets and quotes
            if parent.themeManager.autoPairBrackets() {
                if let pairResult = handleAutoPair(textView: textView, input: string, charRange: charRange) {
                    textView.insertText(pairResult, replacementRange: charRange)
                    return false
                }
            }

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

        // MARK: - Auto-Pair Brackets and Quotes

        private func handleAutoPair(textView: NSTextView, input: String, charRange: NSRange) -> String? {
            let pairs: [String: String] = [
                "(": ")",
                "[": "]",
                "{": "}",
                "\"": "\"",
                "'": "'",
                "`": "`"
            ]

            guard let closing = pairs[input] else { return nil }

            // Check if there's a selection - wrap it
            if charRange.length > 0 {
                let text = textView.string as NSString
                let selectedText = text.substring(with: charRange)
                return input + selectedText + closing
            }

            // Insert both opening and closing, cursor in between
            return input + closing
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

        // MARK: - Trailing Whitespace Highlighting

        private func applyTrailingWhitespaceHighlighting(to textView: NSTextView, lineRange: NSRange? = nil) {
            guard ThemeManager.shared.highlightTrailingWhitespace() else { return }

            let content = textView.string as NSString
            let theme = parent.themeManager.currentTheme

            // Use a subtle red color for trailing whitespace
            let trailingColor = NSColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.4)

            // If lineRange is provided, only highlight that specific line
            if let range = lineRange {
                let lineString = content.substring(with: range)
                let lineLength = lineString.count

                var trailingStart = lineLength
                var index = lineLength - 1
                while index >= 0 {
                    let char = lineString[lineString.index(lineString.startIndex, offsetBy: index)]
                    if char == " " || char == "\t" {
                        trailingStart = index
                        index -= 1
                    } else {
                        break
                    }
                }

                if trailingStart < lineLength {
                    let trailingLength = lineLength - trailingStart
                    let trailingRange = NSRange(location: range.location + trailingStart, length: trailingLength)
                    textView.textStorage?.addAttribute(.foregroundColor, value: trailingColor, range: trailingRange)
                }
                return
            }

            // Full document highlighting (original behavior)
            let lines = content.components(separatedBy: "\n")
            var currentLocation = 0

            for line in lines {
                // Find trailing whitespace in this line
                let lineLength = line.count
                var trailingStart = lineLength

                // Scan from end of line to find trailing whitespace
                var index = lineLength - 1
                while index >= 0 {
                    let char = line[line.index(line.startIndex, offsetBy: index)]
                    if char == " " || char == "\t" {
                        trailingStart = index
                        index -= 1
                    } else {
                        break
                    }
                }

                // If there's trailing whitespace, highlight it
                if trailingStart < lineLength {
                    let trailingLength = lineLength - trailingStart
                    let range = NSRange(location: currentLocation + trailingStart, length: trailingLength)
                    textView.textStorage?.addAttribute(.foregroundColor, value: trailingColor, range: range)
                }

                // Move to next line (+1 for newline character)
                currentLocation += lineLength + 1
            }
        }
    }
}

// MARK: - Line Length Guide View

class LineLengthGuideView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard ThemeManager.shared.showLineLengthGuide() else { return }

        let column = ThemeManager.shared.lineLengthGuideColumn()
        let fontSize = ThemeManager.shared.fontSize()

        // Calculate x position based on character width (approximate for monospace)
        let charWidth = floor(fontSize * 0.6) // Approximate width for SF Mono
        let gutterWidth: CGFloat = 48
        let padding: CGFloat = 8
        let xPosition = gutterWidth + padding + CGFloat(column - 1) * charWidth

        // Draw vertical line
        let path = NSBezierPath()
        path.move(to: NSPoint(x: xPosition, y: 0))
        path.line(to: NSPoint(x: xPosition, y: bounds.height))

        // Use a subtle color for the guide line
        let guideColor = NSColor.secondaryLabelColor.withAlphaComponent(0.3)
        guideColor.setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}
