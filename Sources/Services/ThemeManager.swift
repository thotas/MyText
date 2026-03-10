import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: EditorTheme

    let themes: [EditorTheme] = [
        EditorTheme.dark,
        EditorTheme.light,
        EditorTheme.midnight,
        EditorTheme.monokai,
        EditorTheme.dracula
    ]

    private init() {
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        currentTheme = themes.first(where: { $0.name == savedThemeName }) ?? .dark
    }

    func setTheme(_ theme: EditorTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.name, forKey: "selectedTheme")
    }

    func fontSize() -> Double {
        UserDefaults.standard.double(forKey: "fontSize").nonZero ?? 14.0
    }

    func setFontSize(_ size: Double) {
        UserDefaults.standard.set(size, forKey: "fontSize")
    }

    func fontName() -> String {
        UserDefaults.standard.string(forKey: "fontName") ?? "SF Mono"
    }

    func setFontName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "fontName")
    }

    func tabWidth() -> Int {
        let width = UserDefaults.standard.integer(forKey: "tabWidth")
        return width > 0 ? width : 4
    }

    func setTabWidth(_ width: Int) {
        UserDefaults.standard.set(width, forKey: "tabWidth")
    }

    func showLineNumbers() -> Bool {
        if UserDefaults.standard.object(forKey: "showLineNumbers") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "showLineNumbers")
    }

    func setShowLineNumbers(_ show: Bool) {
        UserDefaults.standard.set(show, forKey: "showLineNumbers")
    }

    private let recentFilesKey = "recentFiles"
    private let maxRecentFiles = 10

    func recentFiles() -> [URL] {
        guard let paths = UserDefaults.standard.stringArray(forKey: recentFilesKey) else {
            return []
        }
        let urls = paths.compactMap { URL(fileURLWithPath: $0) }
        // Filter to only return files that actually exist
        return urls.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func addRecentFile(_ url: URL) {
        var files = recentFiles()
        files.removeAll { $0 == url }
        files.insert(url, at: 0)
        if files.count > maxRecentFiles {
            files = Array(files.prefix(maxRecentFiles))
        }
        UserDefaults.standard.set(files.map { $0.path }, forKey: recentFilesKey)
    }

    func removeRecentFile(_ url: URL) {
        var files = recentFiles()
        files.removeAll { $0 == url }
        UserDefaults.standard.set(files.map { $0.path }, forKey: recentFilesKey)
    }
}

struct EditorTheme: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let background: Color
    let editorBackground: Color
    let text: Color
    let selection: Color
    let cursor: Color
    let lineNumber: Color
    let lineNumberHighlight: Color
    let gutterBackground: Color
    let toolbar: Color
    let currentLineBackground: String

    // Syntax highlighting colors
    let keyword: Color
    let string: Color
    let number: Color
    let comment: Color
    let function: Color
    let type: Color
    let variable: Color
    let `operator`: Color
    let preprocessor: Color

    static let dark = EditorTheme(
        name: "Dark",
        background: Color(hex: "1E1E1E"),
        editorBackground: Color(hex: "252526"),
        text: Color(hex: "D4D4D4"),
        selection: Color(hex: "264F78").opacity(0.6),
        cursor: Color(hex: "FFFFFF"),
        lineNumber: Color(hex: "858585"),
        lineNumberHighlight: Color(hex: "C6C6C6"),
        gutterBackground: Color(hex: "1E1E1E"),
        toolbar: Color(hex: "323233"),
        currentLineBackground: "#2D2D2D",
        keyword: Color(hex: "569CD6"),
        string: Color(hex: "CE9178"),
        number: Color(hex: "B5CEA8"),
        comment: Color(hex: "6A9955"),
        function: Color(hex: "DCDCAA"),
        type: Color(hex: "4EC9B0"),
        variable: Color(hex: "9CDCFE"),
        `operator`: Color(hex: "D4D4D4"),
        preprocessor: Color(hex: "C586C0")
    )

    static let light = EditorTheme(
        name: "Light",
        background: Color(hex: "FFFFFF"),
        editorBackground: Color(hex: "FAFAFA"),
        text: Color(hex: "333333"),
        selection: Color(hex: "ADD6FF").opacity(0.6),
        cursor: Color(hex: "000000"),
        lineNumber: Color(hex: "237893"),
        lineNumberHighlight: Color(hex: "0B244A"),
        gutterBackground: Color(hex: "F5F5F5"),
        toolbar: Color(hex: "F0F0F0"),
        currentLineBackground: "#F5F5F5",
        keyword: Color(hex: "0000FF"),
        string: Color(hex: "A31515"),
        number: Color(hex: "098658"),
        comment: Color(hex: "008000"),
        function: Color(hex: "795E26"),
        type: Color(hex: "267F99"),
        variable: Color(hex: "001080"),
        `operator`: Color(hex: "000000"),
        preprocessor: Color(hex: "AF00DB")
    )

    static let midnight = EditorTheme(
        name: "Midnight",
        background: Color(hex: "0F0F23"),
        editorBackground: Color(hex: "1A1A2E"),
        text: Color(hex: "E0E0E0"),
        selection: Color(hex: "4A4A6A").opacity(0.6),
        cursor: Color(hex: "FFFFFF"),
        lineNumber: Color(hex: "6B6B8D"),
        lineNumberHighlight: Color(hex: "FFFFFF"),
        gutterBackground: Color(hex: "0F0F23"),
        toolbar: Color(hex: "16162A"),
        currentLineBackground: "#1F1F3A",
        keyword: Color(hex: "BD93F9"),
        string: Color(hex: "F1FA8C"),
        number: Color(hex: "BD93F9"),
        comment: Color(hex: "6272A4"),
        function: Color(hex: "50FA7B"),
        type: Color(hex: "8BE9FD"),
        variable: Color(hex: "F8F8F2"),
        `operator`: Color(hex: "FF79C6"),
        preprocessor: Color(hex: "FF79C6")
    )

    static let monokai = EditorTheme(
        name: "Monokai",
        background: Color(hex: "272822"),
        editorBackground: Color(hex: "272822"),
        text: Color(hex: "F8F8F2"),
        selection: Color(hex: "49483E").opacity(0.6),
        cursor: Color(hex: "F8F8F0"),
        lineNumber: Color(hex: "90908A"),
        lineNumberHighlight: Color(hex: "F8F8F0"),
        gutterBackground: Color(hex: "272822"),
        toolbar: Color(hex: "3E3D32"),
        currentLineBackground: "#3E3D32",
        keyword: Color(hex: "F92672"),
        string: Color(hex: "E6DB74"),
        number: Color(hex: "AE81FF"),
        comment: Color(hex: "75715E"),
        function: Color(hex: "A6E22E"),
        type: Color(hex: "66D9EF"),
        variable: Color(hex: "F8F8F2"),
        `operator`: Color(hex: "F92672"),
        preprocessor: Color(hex: "F92672")
    )

    static let dracula = EditorTheme(
        name: "Dracula",
        background: Color(hex: "282A36"),
        editorBackground: Color(hex: "282A36"),
        text: Color(hex: "F8F8F2"),
        selection: Color(hex: "44475A").opacity(0.6),
        cursor: Color(hex: "F8F8F2"),
        lineNumber: Color(hex: "6272A4"),
        lineNumberHighlight: Color(hex: "F8F8F2"),
        gutterBackground: Color(hex: "282A36"),
        toolbar: Color(hex: "343746"),
        currentLineBackground: "#44475A",
        keyword: Color(hex: "FF79C6"),
        string: Color(hex: "F1FA8C"),
        number: Color(hex: "BD93F9"),
        comment: Color(hex: "6272A4"),
        function: Color(hex: "50FA7B"),
        type: Color(hex: "8BE9FD"),
        variable: Color(hex: "F8F8F2"),
        `operator`: Color(hex: "FF79C6"),
        preprocessor: Color(hex: "FF79C6")
    )
}

extension Double {
    var nonZero: Double? {
        self > 0 ? self : nil
    }
}

extension Int {
    var nonZero: Int? {
        self > 0 ? self : nil
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
