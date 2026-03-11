import SwiftUI
import Combine
import AppKit

// MARK: - Fold Region

struct FoldRegion: Identifiable {
    let id = UUID()
    let startLine: Int
    let endLine: Int
    var isFolded: Bool

    var lineCount: Int {
        endLine - startLine + 1
    }
}

@MainActor
class EditorViewModel: ObservableObject {
    @Published var document: TextDocument
    @Published var editorState = EditorState()
    @Published var detectedLanguage: ProgrammingLanguage = .plainText
    @Published var showSidebar: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var wordWrap: Bool = false
    @Published var foldRegions: [FoldRegion] = []
    @Published var findQuery: String = ""

    // Weak reference to text view for line operations
    weak var textView: NSTextView?

    let syntaxHighlighter: SyntaxHighlighter
    let themeManager = ThemeManager.shared

    var tabWidth: Int {
        UserDefaults.standard.integer(forKey: "tabWidth").nonZero ?? 4
    }

    init(document: TextDocument = TextDocument(content: "")) {
        self.document = document
        self.syntaxHighlighter = SyntaxHighlighter()
        self.wordWrap = UserDefaults.standard.bool(forKey: "wordWrap")
        startAutoSaveTimer()
    }

    private var autoSaveTimer: Timer?

    func startAutoSaveTimer() {
        let interval = TimeInterval(ThemeManager.shared.autoSaveInterval())
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performAutoSave()
            }
        }
    }

    private func performAutoSave() {
        guard ThemeManager.shared.autoSaveEnabled() else { return }
        guard document.isModified else { return }
        guard document.fileURL != nil else { return } // Only auto-save if file has a path

        // Save to the existing file
        saveDocument()
    }

    func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    // MARK: - Code Folding

    func detectFoldRegions() {
        foldRegions = syntaxHighlighter.detectFoldRegions(
            in: document.content,
            language: detectedLanguage
        )
    }

    func toggleFold(at line: Int) {
        // Find if this line is a fold start or end
        if let index = foldRegions.firstIndex(where: { $0.startLine == line }) {
            foldRegions[index].isFolded.toggle()
        } else if let index = foldRegions.firstIndex(where: { $0.endLine == line }) {
            foldRegions[index].isFolded.toggle()
        }
        applyFolds()
    }

    func toggleFoldAtCursor() {
        guard let textView = textView else { return }
        let cursorPos = textView.selectedRange().location
        let lineNumber = getLineNumber(at: cursorPos)
        toggleFold(at: lineNumber)
    }

    private func getLineNumber(at position: Int) -> Int {
        let content = textView?.string ?? ""
        var line = 1
        var currentPos = 0
        for char in content {
            if currentPos >= position { break }
            if char == "\n" { line += 1 }
            currentPos += 1
        }
        return line
    }

    func foldAll() {
        for index in foldRegions.indices {
            foldRegions[index].isFolded = true
        }
        applyFolds()
    }

    func unfoldAll() {
        for index in foldRegions.indices {
            foldRegions[index].isFolded = false
        }
        applyFolds()
    }

    func isLineFolded(_ line: Int) -> Bool {
        for region in foldRegions where region.isFolded {
            if line > region.startLine && line <= region.endLine {
                return true
            }
        }
        return false
    }

    func getFoldIndicator(for line: Int) -> FoldIndicator? {
        for region in foldRegions {
            if region.startLine == line {
                return region.isFolded ? .expanded : .collapsed
            }
            if region.endLine == line && region.isFolded {
                return .end
            }
        }
        return nil
    }

    private func applyFolds() {
        // Notify the text view to update visible ranges
        NotificationCenter.default.post(name: .foldStateChanged, object: nil)
    }

    enum FoldIndicator {
        case collapsed
        case expanded
        case end
    }

    func toggleWordWrap() {
        wordWrap.toggle()
        UserDefaults.standard.set(wordWrap, forKey: "wordWrap")
    }

    func setTextView(_ textView: NSTextView?) {
        self.textView = textView
    }

    func updateCursorPosition() {
        let content = document.content
        let cursorPos = min(editorState.cursorPosition, content.count)

        var line = 1
        var column = 1

        for (index, char) in content.enumerated() {
            if index >= cursorPos { break }
            if char == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
        }

        editorState.lineNumber = line
        editorState.columnNumber = column
    }

    func detectLanguage() {
        let ext = document.fileExtension
        let language = ProgrammingLanguage.fromExtension(ext)
        detectedLanguage = language
    }

    func setLanguage(_ language: ProgrammingLanguage) {
        detectedLanguage = language
    }

    func newDocument() {
        document = TextDocument(content: "")
        editorState = EditorState()
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .shellScript, .sourceCode, .pythonScript]

        if panel.runModal() == .OK, let url = panel.url {
            loadDocument(from: url)
        }
    }

    func loadDocument(from url: URL) {
        isLoading = true
        errorMessage = nil

        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "File not found: \(url.lastPathComponent)"
            isLoading = false
            // Remove stale entry from recent files
            themeManager.removeRecentFile(url)
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            document = TextDocument(content: content, fileURL: url)
            detectLanguage()
            // Detect line ending from file content
            document.lineEnding = detectLineEnding(from: content)
            themeManager.addRecentFile(url)
        } catch {
            errorMessage = "Error loading document: \(error.localizedDescription)"
            print("Error loading document: \(error)")
        }
        isLoading = false
    }

    private func detectLineEnding(from content: String) -> TextDocument.LineEnding {
        if content.contains("\r\n") {
            return .windows
        } else if content.contains("\r") {
            return .mac
        }
        return .unix
    }

    func saveDocument() {
        guard let url = document.fileURL else {
            saveDocumentAs()
            return
        }

        // Trim trailing whitespace if setting is enabled
        var contentToSave = document.content
        if UserDefaults.standard.bool(forKey: "trimTrailingWhitespace") {
            contentToSave = trimTrailingWhitespace(from: contentToSave)
            // Update document content if we trimmed
            if contentToSave != document.content {
                document.content = contentToSave
            }
        }

        do {
            try contentToSave.write(to: url, atomically: true, encoding: document.encoding)
            document.isModified = false
        } catch {
            print("Error saving document: \(error)")
        }
    }

    func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = document.fileName

        if panel.runModal() == .OK, let url = panel.url {
            document.fileURL = url
            saveDocument()
        }
    }

    private func trimTrailingWhitespace(from text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        let trimmedLines = lines.map { line in
            var trimmed = line
            while let last = trimmed.last, last == " " || last == "\t" {
                trimmed.removeLast()
            }
            return trimmed
        }
        return trimmedLines.joined(separator: "\n")
    }

    func trimTrailingWhitespaceCommand() {
        let trimmed = trimTrailingWhitespace(from: document.content)
        if trimmed != document.content {
            document.content = trimmed
            document.isModified = true
        }
    }

    func convertToSpaces() {
        let tabWidth = self.tabWidth
        let converted = convertIndentation(in: document.content, toSpaces: true, tabWidth: tabWidth)
        if converted != document.content {
            document.content = converted
            document.isModified = true
        }
    }

    func convertToTabs() {
        let tabWidth = self.tabWidth
        let converted = convertIndentation(in: document.content, toSpaces: false, tabWidth: tabWidth)
        if converted != document.content {
            document.content = converted
            document.isModified = true
        }
    }

    // MARK: - Line Ending Conversion

    func convertLineEndings(_ lineEnding: LineEnding) {
        let converted = convertLineEndings(in: document.content, to: lineEnding)
        if converted != document.content {
            document.content = converted
            document.isModified = true
        }
        // Update document's line ending
        document.lineEnding = lineEnding.toDocumentLineEnding()
    }

    private func convertLineEndings(in text: String, to lineEnding: LineEnding) -> String {
        // First normalize to LF
        var normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Then convert to target
        switch lineEnding {
        case .lf:
            return normalized
        case .crlf:
            return normalized.replacingOccurrences(of: "\n", with: "\r\n")
        case .cr:
            return normalized.replacingOccurrences(of: "\n", with: "\r")
        }
    }

    var currentLineEnding: LineEnding {
        let content = document.content
        if content.contains("\r\n") {
            return .crlf
        } else if content.contains("\r") {
            return .cr
        }
        return .lf
    }

    enum LineEnding: String, CaseIterable {
        case lf = "LF (Unix)"
        case crlf = "CRLF (Windows)"
        case cr = "CR (Classic Mac)"

        func toDocumentLineEnding() -> TextDocument.LineEnding {
            switch self {
            case .lf: return .unix
            case .crlf: return .windows
            case .cr: return .mac
            }
        }

        static func fromDocumentLineEnding(_ de: TextDocument.LineEnding) -> LineEnding {
            switch de {
            case .unix: return .lf
            case .windows: return .crlf
            case .mac: return .cr
            }
        }
    }

    private func convertIndentation(in text: String, toSpaces: Bool, tabWidth: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        let convertedLines = lines.map { line -> String in
            var result = ""
            var i = line.startIndex
            while i < line.endIndex {
                let char = line[i]
                if char == "\t" {
                    if toSpaces {
                        result += String(repeating: " ", count: tabWidth)
                    } else {
                        result += "\t"
                    }
                } else if char == " " {
                    // Check if it's leading whitespace that could be a tab
                    var spaceCount = 0
                    var j = i
                    while j < line.endIndex && line[j] == " " && spaceCount < tabWidth {
                        spaceCount += 1
                        j = line.index(after: j)
                    }
                    if spaceCount == tabWidth && !toSpaces {
                        // Convert exactly tabWidth spaces to a tab
                        result += "\t"
                        i = j
                    } else if spaceCount == tabWidth && toSpaces {
                        // Already spaces, keep as is
                        result += String(repeating: " ", count: spaceCount)
                        i = j
                    } else {
                        result.append(char)
                        i = line.index(after: i)
                    }
                } else {
                    result.append(char)
                    i = line.index(after: i)
                }
            }
            return result
        }
        return convertedLines.joined(separator: "\n")
    }

    func updateContent(_ newContent: String) {
        document.content = newContent
        document.isModified = true
    }

    func insertText(_ text: String, at position: Int) {
        var content = document.content
        let index = content.index(content.startIndex, offsetBy: min(position, content.count))
        content.insert(contentsOf: text, at: index)
        document.content = content
        document.isModified = true
    }

    // MARK: - Line Operations

    func duplicateLine() {
        guard let textView = textView else { return }
        let content = textView.string
        let cursorPos = textView.selectedRange().location

        let lines = content.components(separatedBy: "\n")
        var currentPos = 0
        var lineIndex = 0

        for (index, line) in lines.enumerated() {
            if currentPos + line.count >= cursorPos {
                lineIndex = index
                break
            }
            currentPos += line.count + 1
        }

        guard lineIndex < lines.count else { return }
        let line = lines[lineIndex]
        var newLines = lines
        newLines.insert(line, at: lineIndex + 1)
        let newContent = newLines.joined(separator: "\n")
        textView.string = newContent
        document.content = newContent
        document.isModified = true

        // Position cursor after the duplicated line
        var newCursorPos = 0
        for i in 0...lineIndex + 1 {
            if i < newLines.count {
                newCursorPos += newLines[i].count + 1
            }
        }
        textView.setSelectedRange(NSRange(location: min(newCursorPos, newContent.count), length: 0))
    }

    func moveLineUp() {
        guard let textView = textView else { return }
        let content = textView.string
        let cursorPos = textView.selectedRange().location

        let lines = content.components(separatedBy: "\n")
        var currentPos = 0
        var lineIndex = 0

        for (index, line) in lines.enumerated() {
            if currentPos + line.count >= cursorPos {
                lineIndex = index
                break
            }
            currentPos += line.count + 1
        }

        guard lineIndex > 0 && lineIndex < lines.count else { return }

        var newLines = lines
        newLines.swapAt(lineIndex, lineIndex - 1)
        let newContent = newLines.joined(separator: "\n")
        textView.string = newContent
        document.content = newContent
        document.isModified = true

        // Calculate new cursor position
        var newCursorPos = 0
        for i in 0..<(lineIndex - 1) {
            newCursorPos += newLines[i].count + 1
        }
        newCursorPos += newLines[lineIndex - 1].count
        textView.setSelectedRange(NSRange(location: min(newCursorPos, newContent.count), length: 0))
    }

    func moveLineDown() {
        guard let textView = textView else { return }
        let content = textView.string
        let cursorPos = textView.selectedRange().location

        let lines = content.components(separatedBy: "\n")
        var currentPos = 0
        var lineIndex = 0

        for (index, line) in lines.enumerated() {
            if currentPos + line.count >= cursorPos {
                lineIndex = index
                break
            }
            currentPos += line.count + 1
        }

        guard lineIndex < lines.count - 1 else { return }

        var newLines = lines
        newLines.swapAt(lineIndex, lineIndex + 1)
        let newContent = newLines.joined(separator: "\n")
        textView.string = newContent
        document.content = newContent
        document.isModified = true

        // Calculate new cursor position
        var newCursorPos = 0
        for i in 0...(lineIndex + 1) {
            newCursorPos += newLines[i].count + 1
        }
        newCursorPos += newLines[lineIndex + 1].count
        textView.setSelectedRange(NSRange(location: min(newCursorPos, newContent.count), length: 0))
    }

    func selectLine() {
        guard let textView = textView else { return }
        let content = textView.string
        let cursorPos = textView.selectedRange().location

        let string = content as NSString
        let lineRange = string.lineRange(for: NSRange(location: cursorPos, length: 0))

        // Select the entire line
        textView.setSelectedRange(NSRange(location: lineRange.location, length: lineRange.length))
    }

    func jumpToMatchingBracket() {
        guard let textView = textView else { return }

        let selectedRange = textView.selectedRange()
        guard selectedRange.location > 0 else { return }

        let string = textView.string as NSString
        let charIndex = selectedRange.location - 1
        guard charIndex < string.length else { return }

        let char = Character(UnicodeScalar(string.character(at: charIndex))!)

        let bracketPairs: [Character: Character] = [
            "(": ")",
            "[": "]",
            "{": "}",
            "<": ">"
        ]
        let closingBrackets: Set<Character> = [")", "]", "}", ">"]

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

    func selectAllOccurrences() {
        guard let textView = textView else { return }

        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }

        let string = textView.string as NSString
        let selectedText = string.substring(with: selectedRange)

        guard !selectedText.isEmpty else { return }

        // Find all occurrences
        var allRanges: [NSRange] = []
        var searchStart = 0

        while searchStart < string.length {
            let searchRange = NSRange(location: searchStart, length: string.length - searchStart)
            let searchString = string.substring(with: searchRange)

            guard let range = searchString.range(of: selectedText, options: .caseInsensitive) else {
                break
            }

            let absoluteStart = searchRange.location + searchString.distance(from: searchString.startIndex, to: range.lowerBound)
            let foundRange = NSRange(location: absoluteStart, length: selectedText.count)

            // Don't add the original selection (we'll keep it as the main selection)
            if foundRange != selectedRange {
                allRanges.append(foundRange)
            }

            searchStart = absoluteStart + selectedText.count
        }

        guard !allRanges.isEmpty else { return }

        // Select all occurrences by combining all ranges
        // We'll select from first to last occurrence
        let firstRange = allRanges.first!
        let lastRange = allRanges.last!
        let combinedRange = NSRange(location: firstRange.location, length: lastRange.location + lastRange.length - firstRange.location)

        textView.setSelectedRange(combinedRange)
    }

    func toggleComment() {
        guard let textView = textView else { return }
        let content = textView.string
        let cursorPos = textView.selectedRange().location

        let lines = content.components(separatedBy: "\n")
        var currentPos = 0
        var lineIndex = 0

        for (index, line) in lines.enumerated() {
            if currentPos + line.count >= cursorPos {
                lineIndex = index
                break
            }
            currentPos += line.count + 1
        }

        guard lineIndex < lines.count else { return }

        var newLines = lines
        let line = lines[lineIndex]

        // Determine if line is commented
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix("//") {
            // Remove comment
            let commentStart = line.firstIndex(of: "/")!
            newLines[lineIndex] = String(line[..<commentStart]) + String(line[line.index(after: commentStart)...])
        } else {
            // Add comment at start (after any leading whitespace)
            let leadingWhitespace = String(line.prefix(while: { $0.isWhitespace }))
            newLines[lineIndex] = leadingWhitespace + "//" + String(line.dropFirst(leadingWhitespace.count))
        }

        let newContent = newLines.joined(separator: "\n")
        textView.string = newContent
        document.content = newContent
        document.isModified = true

        // Position cursor after the comment
        var newCursorPos = 0
        for i in 0...lineIndex {
            newCursorPos += newLines[i].count + 1
        }
        textView.setSelectedRange(NSRange(location: min(newCursorPos, newContent.count), length: 0))
    }

    // MARK: - Text Transformation

    func uppercaseSelection() {
        guard let textView = textView else { return }
        let selectedRange = textView.selectedRange()

        guard selectedRange.length > 0 else { return }

        let content = textView.string as NSString
        let selectedText = content.substring(with: selectedRange)
        let uppercased = selectedText.uppercased()

        textView.insertText(uppercased, replacementRange: selectedRange)
        document.content = textView.string
        document.isModified = true
    }

    func lowercaseSelection() {
        guard let textView = textView else { return }
        let selectedRange = textView.selectedRange()

        guard selectedRange.length > 0 else { return }

        let content = textView.string as NSString
        let selectedText = content.substring(with: selectedRange)
        let lowercased = selectedText.lowercased()

        textView.insertText(lowercased, replacementRange: selectedRange)
        document.content = textView.string
        document.isModified = true
    }

    func sortLines() {
        guard let textView = textView else { return }
        let content = textView.string
        let selectedRange = textView.selectedRange()

        let string = content as NSString
        let lineRange: NSRange

        if selectedRange.length > 0 {
            // Sort selected lines
            lineRange = string.lineRange(for: selectedRange)
        } else {
            // Sort all lines
            lineRange = NSRange(location: 0, length: string.length)
        }

        let selectedText = string.substring(with: lineRange)
        var lines = selectedText.components(separatedBy: "\n")

        // Sort lines alphabetically (case-insensitive)
        lines.sort { $0.lowercased() < $1.lowercased() }

        let sortedText = lines.joined(separator: "\n")
        textView.insertText(sortedText, replacementRange: lineRange)
        document.content = textView.string
        document.isModified = true
    }

    // MARK: - Find & Replace

    func replaceNext(searchText: String, replaceWith: String) {
        guard let textView = textView, !searchText.isEmpty else { return }

        let content = textView.string
        let selectedRange = textView.selectedRange()

        // Check if there's a selection that matches the search text
        if selectedRange.length > 0 {
            let startIndex = content.index(content.startIndex, offsetBy: selectedRange.location)
            let endIndex = content.index(startIndex, offsetBy: selectedRange.length)
            let selectedText = String(content[startIndex..<endIndex])

            let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive
            if selectedText == searchText || selectedText.lowercased() == searchText.lowercased() {
                // Replace the selection
                textView.insertText(replaceWith, replacementRange: selectedRange)
                document.content = textView.string
                document.isModified = true

                // Find next match after the replacement
                findNext(searchText: searchText, isRegex: false)
                return
            }
        }

        // If no selection or no match, find and replace next occurrence
        findNext(searchText: searchText, isRegex: false)
    }

    func replaceAll(searchText: String, replaceWith: String) {
        guard let textView = textView, !searchText.isEmpty else { return }

        let content = textView.string
        var options: String.CompareOptions = []
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }

        // Replace all occurrences
        var newContent = content
        if caseSensitive {
            newContent = newContent.replacingOccurrences(of: searchText, with: replaceWith)
        } else {
            newContent = newContent.replacingOccurrences(of: searchText, with: replaceWith, options: .caseInsensitive)
        }

        textView.string = newContent
        document.content = newContent
        document.isModified = true

        // Highlight matches to show results
        highlightMatches(searchText)
    }

    func findNext(searchText: String, isRegex: Bool) {
        guard let textView = textView, !searchText.isEmpty else { return }

        let content = textView.string
        let currentPos = textView.selectedRange().location

        var options: String.CompareOptions = []
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }

        // Search from current position + 1 to end
        let searchStart = min(currentPos + 1, content.count)
        let searchRange = content.index(content.startIndex, offsetBy: searchStart)..<content.endIndex

        if let range = content.range(of: searchText, options: options, range: searchRange) {
            let loc = content.distance(from: content.startIndex, to: range.lowerBound)
            let length = content.distance(from: range.lowerBound, to: range.upperBound)
            textView.setSelectedRange(NSRange(location: loc, length: length))
            textView.scrollRangeToVisible(NSRange(location: loc, length: length))
        } else {
            // Wrap around - search from beginning
            if let range = content.range(of: searchText, options: options) {
                let loc = content.distance(from: content.startIndex, to: range.lowerBound)
                let length = content.distance(from: range.lowerBound, to: range.upperBound)
                textView.setSelectedRange(NSRange(location: loc, length: length))
                textView.scrollRangeToVisible(NSRange(location: loc, length: length))
            }
        }
    }

    func findPrevious(searchText: String, isRegex: Bool) {
        guard let textView = textView, !searchText.isEmpty else { return }

        let content = textView.string
        let currentPos = textView.selectedRange().location

        var options: String.CompareOptions = [.backwards]
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }

        // Search from beginning to current position - 1
        let searchEnd = max(0, currentPos - 1)
        let searchRange = content.startIndex..<content.index(content.startIndex, offsetBy: searchEnd)

        if let range = content.range(of: searchText, options: options, range: searchRange) {
            let loc = content.distance(from: content.startIndex, to: range.lowerBound)
            let length = content.distance(from: range.lowerBound, to: range.upperBound)
            textView.setSelectedRange(NSRange(location: loc, length: length))
            textView.scrollRangeToVisible(NSRange(location: loc, length: length))
        } else {
            // Wrap around - search from end
            if let range = content.range(of: searchText, options: options) {
                let loc = content.distance(from: content.startIndex, to: range.lowerBound)
                let length = content.distance(from: range.lowerBound, to: range.upperBound)
                textView.setSelectedRange(NSRange(location: loc, length: length))
                textView.scrollRangeToVisible(NSRange(location: loc, length: length))
            }
        }
    }

    func highlightMatches(_ searchText: String) {
        guard let textView = textView, !searchText.isEmpty else {
            clearMatchHighlights()
            return
        }

        let content = textView.string
        var options: String.CompareOptions = []
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }

        // Clear existing highlights first
        clearMatchHighlights()

        // Find all matches and highlight them
        var searchRange = content.startIndex..<content.endIndex
        let yellowColor = NSColor.yellow.withAlphaComponent(0.4)

        while let range = content.range(of: searchText, options: options, range: searchRange) {
            let loc = content.distance(from: content.startIndex, to: range.lowerBound)
            let length = content.distance(from: range.lowerBound, to: range.upperBound)
            let nsRange = NSRange(location: loc, length: length)

            // Add temporary attribute for highlight
            textView.textStorage?.addAttribute(.backgroundColor, value: yellowColor, range: nsRange)

            searchRange = range.upperBound..<content.endIndex
        }
    }

    func clearMatchHighlights() {
        guard let textView = textView else { return }

        let fullRange = NSRange(location: 0, length: textView.string.count)
        if let textStorage = textView.textStorage {
            textStorage.removeAttribute(.backgroundColor, range: fullRange)
        }
    }

    private var caseSensitive: Bool {
        false
    }
}

enum ProgrammingLanguage: String, CaseIterable {
    case plainText = "Plain Text"
    case shell = "Shell Script"
    case sql = "SQL"
    case python = "Python"

    var displayName: String { rawValue }

    var fileExtensions: [String] {
        switch self {
        case .plainText: return ["txt", "text", "md", "log"]
        case .shell: return ["sh", "bash", "zsh", "fish", "csh"]
        case .sql: return ["sql", "pgsql", "mysql"]
        case .python: return ["py", "pyw", "pyi"]
        }
    }

    static func fromExtension(_ ext: String) -> ProgrammingLanguage {
        for language in ProgrammingLanguage.allCases {
            if language.fileExtensions.contains(ext.lowercased()) {
                return language
            }
        }
        return .plainText
    }
}
