import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: EditorTheme
    @Published var syncWithSystem: Bool {
        didSet {
            UserDefaults.standard.set(syncWithSystem, forKey: "syncWithSystem")
            if syncWithSystem {
                updateForSystemAppearance()
            } else {
                // When sync is turned off, restore the last selected theme
                let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
                if let theme = themes.first(where: { $0.name == savedThemeName }) {
                    currentTheme = theme
                }
            }
        }
    }

    @Published var customThemes: [EditorTheme] = []

    private var cancellables = Set<AnyCancellable>()

    let builtInThemes: [EditorTheme] = [
        EditorTheme.dark,
        EditorTheme.light,
        EditorTheme.midnight,
        EditorTheme.monokai,
        EditorTheme.dracula
    ]

    var themes: [EditorTheme] {
        builtInThemes + customThemes
    }

    private let customThemesKey = "customThemes"

    private init() {
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        let savedSyncWithSystem = UserDefaults.standard.bool(forKey: "syncWithSystem")

        syncWithSystem = savedSyncWithSystem
        customThemes = ThemeManager.loadCustomThemesFromDefaults()
        currentTheme = EditorTheme.dark

        // Set initial theme based on system if sync is enabled
        if syncWithSystem {
            updateForSystemAppearance()
        } else {
            currentTheme = (builtInThemes + customThemes).first(where: { $0.name == savedThemeName }) ?? .dark
        }

        // Observe system appearance changes
        setupAppearanceObserver()
    }

    private func setupAppearanceObserver() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeOcclusionStateNotification)
            .sink { [weak self] _ in
                self?.handleAppearanceChange()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppearanceChange()
            }
            .store(in: &cancellables)
    }

    private func handleAppearanceChange() {
        guard syncWithSystem else { return }
        updateForSystemAppearance()
    }

    func updateForSystemAppearance() {
        guard syncWithSystem else { return }
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        currentTheme = isDark ? EditorTheme.dark : EditorTheme.light
        UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
    }

    // MARK: - Custom Theme Management

    func saveCustomTheme(_ theme: EditorTheme, name: String) {
        var themed = theme
        themed.name = name
        customThemes.append(themed)
        saveCustomThemesToDefaults()
    }

    func deleteCustomTheme(_ theme: EditorTheme) {
        customThemes.removeAll { $0.id == theme.id }
        saveCustomThemesToDefaults()
    }

    func importTheme(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let themeData = try decoder.decode(ThemeData.self, from: data)
        let theme = themeData.toEditorTheme()

        // Check for name conflicts
        var finalName = theme.name
        var counter = 1
        while themes.contains(where: { $0.name == finalName }) {
            finalName = "\(theme.name) \(counter)"
            counter += 1
        }

        var themed = theme
        themed.name = finalName
        customThemes.append(themed)
        saveCustomThemesToDefaults()
    }

    func exportTheme(_ theme: EditorTheme, to url: URL) throws {
        let themeData = ThemeData(from: theme)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(themeData)
        try data.write(to: url)
    }

    private func saveCustomThemesToDefaults() {
        let themeDataList = customThemes.map { ThemeData(from: $0) }
        if let data = try? JSONEncoder().encode(themeDataList) {
            UserDefaults.standard.set(data, forKey: customThemesKey)
        }
    }

    private static func loadCustomThemesFromDefaults() -> [EditorTheme] {
        guard let data = UserDefaults.standard.data(forKey: "customThemes"),
              let themeDataList = try? JSONDecoder().decode([ThemeData].self, from: data) else {
            return []
        }
        return themeDataList.map { $0.toEditorTheme() }
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

    func showInvisibles() -> Bool {
        UserDefaults.standard.bool(forKey: "showInvisibles")
    }

    func setShowInvisibles(_ show: Bool) {
        UserDefaults.standard.set(show, forKey: "showInvisibles")
    }

    func highlightTrailingWhitespace() -> Bool {
        UserDefaults.standard.bool(forKey: "highlightTrailingWhitespace")
    }

    func setHighlightTrailingWhitespace(_ highlight: Bool) {
        UserDefaults.standard.set(highlight, forKey: "highlightTrailingWhitespace")
    }

    func autoSaveEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: "autoSaveEnabled") == nil {
            return true // Default to enabled
        }
        return UserDefaults.standard.bool(forKey: "autoSaveEnabled")
    }

    func setAutoSaveEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "autoSaveEnabled")
    }

    func autoSaveInterval() -> Int {
        let interval = UserDefaults.standard.integer(forKey: "autoSaveInterval")
        return interval > 0 ? interval : 30 // Default 30 seconds
    }

    func setAutoSaveInterval(_ seconds: Int) {
        UserDefaults.standard.set(seconds, forKey: "autoSaveInterval")
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
    var id = UUID()
    var name: String
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

// Codable struct for JSON theme export/import
struct ThemeData: Codable {
    let name: String
    let background: String
    let editorBackground: String
    let text: String
    let selection: String
    let cursor: String
    let lineNumber: String
    let lineNumberHighlight: String
    let gutterBackground: String
    let toolbar: String
    let currentLineBackground: String
    let keyword: String
    let string: String
    let number: String
    let comment: String
    let function: String
    let type: String
    let variable: String
    let `operator`: String
    let preprocessor: String

    init(from theme: EditorTheme) {
        self.name = theme.name
        self.background = theme.background.hexString
        self.editorBackground = theme.editorBackground.hexString
        self.text = theme.text.hexString
        self.selection = theme.selection.hexString
        self.cursor = theme.cursor.hexString
        self.lineNumber = theme.lineNumber.hexString
        self.lineNumberHighlight = theme.lineNumberHighlight.hexString
        self.gutterBackground = theme.gutterBackground.hexString
        self.toolbar = theme.toolbar.hexString
        self.currentLineBackground = theme.currentLineBackground
        self.keyword = theme.keyword.hexString
        self.string = theme.string.hexString
        self.number = theme.number.hexString
        self.comment = theme.comment.hexString
        self.function = theme.function.hexString
        self.type = theme.type.hexString
        self.variable = theme.variable.hexString
        self.operator = theme.operator.hexString
        self.preprocessor = theme.preprocessor.hexString
    }

    func toEditorTheme() -> EditorTheme {
        EditorTheme(
            name: name,
            background: Color(hex: background),
            editorBackground: Color(hex: editorBackground),
            text: Color(hex: text),
            selection: Color(hex: selection).opacity(0.6),
            cursor: Color(hex: cursor),
            lineNumber: Color(hex: lineNumber),
            lineNumberHighlight: Color(hex: lineNumberHighlight),
            gutterBackground: Color(hex: gutterBackground),
            toolbar: Color(hex: toolbar),
            currentLineBackground: currentLineBackground,
            keyword: Color(hex: keyword),
            string: Color(hex: string),
            number: Color(hex: number),
            comment: Color(hex: comment),
            function: Color(hex: function),
            type: Color(hex: type),
            variable: Color(hex: variable),
            operator: Color(hex: `operator`),
            preprocessor: Color(hex: preprocessor)
        )
    }
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

    var hexString: String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
