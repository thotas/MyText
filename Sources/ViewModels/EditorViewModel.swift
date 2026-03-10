import SwiftUI
import Combine
import AppKit

@MainActor
class EditorViewModel: ObservableObject {
    @Published var document: TextDocument
    @Published var editorState = EditorState()
    @Published var detectedLanguage: ProgrammingLanguage = .plainText
    @Published var showSidebar: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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
            themeManager.addRecentFile(url)
        } catch {
            errorMessage = "Error loading document: \(error.localizedDescription)"
            print("Error loading document: \(error)")
        }
        isLoading = false
    }

    func saveDocument() {
        guard let url = document.fileURL else {
            saveDocumentAs()
            return
        }

        do {
            try document.content.write(to: url, atomically: true, encoding: document.encoding)
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
