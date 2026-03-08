import SwiftUI
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var document: TextDocument
    @Published var editorState = EditorState()
    @Published var detectedLanguage: ProgrammingLanguage = .plainText
    @Published var showSidebar: Bool = true
    @Published var isLoading: Bool = false

    let syntaxHighlighter: SyntaxHighlighter

    init(document: TextDocument = TextDocument(content: "")) {
        self.document = document
        self.syntaxHighlighter = SyntaxHighlighter()
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
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            document = TextDocument(content: content, fileURL: url)
            detectLanguage()
        } catch {
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
