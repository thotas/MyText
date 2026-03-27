import Foundation
import AppKit
import SwiftUI

class SyntaxHighlighter {
    private var languageDefinitions: [ProgrammingLanguage: LanguageDefinition] = [:]

    init() {
        loadLanguageDefinitions()
    }

    private func loadLanguageDefinitions() {
        // Shell Script
        languageDefinitions[.shell] = LanguageDefinition(
            name: "Shell Script",
            patterns: [
                PatternDefinition(name: "comment", pattern: "#.*$", scope: .comment),
                PatternDefinition(name: "string.double", pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", scope: .string),
                PatternDefinition(name: "string.single", pattern: "'(?:[^'\\\\]|\\\\.)*'", scope: .string),
                PatternDefinition(name: "variable", pattern: "\\$\\{?[a-zA-Z_][a-zA-Z0-9_]*\\}?", scope: .variable),
                PatternDefinition(name: "keyword", pattern: "\\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|exit|break|continue|local|declare|readonly|export|unset|shift|source|alias|unalias|echo|printf|read|test|true|false)\\b", scope: .keyword),
                PatternDefinition(name: "function", pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(", scope: .function),
                PatternDefinition(name: "number", pattern: "\\b[0-9]+\\b", scope: .number),
                PatternDefinition(name: "operator", pattern: "[|&;()<>!]", scope: .operator)
            ]
        )

        // SQL
        languageDefinitions[.sql] = LanguageDefinition(
            name: "SQL",
            patterns: [
                PatternDefinition(name: "comment.single", pattern: "--.*$", scope: .comment),
                PatternDefinition(name: "comment.multi", pattern: "/\\*[\\s\\S]*?\\*/", scope: .comment),
                PatternDefinition(name: "string", pattern: "'(?:[^'\\\\]|\\\\.)*'", scope: .string),
                PatternDefinition(name: "keyword", pattern: "\\b(SELECT|FROM|WHERE|AND|OR|NOT|IN|LIKE|BETWEEN|IS|NULL|AS|ON|JOIN|LEFT|RIGHT|INNER|OUTER|FULL|CROSS|UNION|INTERSECT|EXCEPT|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|INDEX|VIEW|DROP|ALTER|ADD|COLUMN|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|DEFAULT|CONSTRAINT|CHECK|CASE|WHEN|THEN|ELSE|END|EXISTS|DISTINCT|COUNT|SUM|AVG|MIN|MAX|ASC|DESC|NULLS|FIRST|LAST|IF|ELSIF|EXCEPTION|RAISE|FOR|LOOP|WHILE|RETURN|GRANT|REVOKE|COMMIT|ROLLBACK|TRANSACTION|BEGIN|DECLARE|CURSOR|PROCEDURE|FUNCTION|TRIGGER|BODY|TYPE|RECORD|TABLE|OF|INTEGER|VARCHAR|DATE|TIMESTAMP|BOOLEAN|FLOAT|DECIMAL|NUMBER|BLOB|CLOB|SEQUENCE|TRUNCATE|MERGE|USING|MATCHED|CONSTRAINT)\\b", scope: .keyword),
                PatternDefinition(name: "function", pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(", scope: .function),
                PatternDefinition(name: "number", pattern: "\\b[0-9]+(?:\\.[0-9]+)?\\b", scope: .number),
                PatternDefinition(name: "operator", pattern: "[=<>!+\\-*/%&|^~]", scope: .operator)
            ]
        )

        // Python
        languageDefinitions[.python] = LanguageDefinition(
            name: "Python",
            patterns: [
                PatternDefinition(name: "comment.single", pattern: "#.*$", scope: .comment),
                PatternDefinition(name: "string.single", pattern: "'''(?:[^'\\\\]|\\\\.)*?'''", scope: .string),
                PatternDefinition(name: "string.double", pattern: "\"\"\"(?:[^\"\\\\]|\\\\.)*?\"\"\"", scope: .string),
                PatternDefinition(name: "string.single", pattern: "'(?:[^'\\\\]|\\\\.)*'", scope: .string),
                PatternDefinition(name: "string.double", pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", scope: .string),
                PatternDefinition(name: "fstring", pattern: "f[\"'](?:[^\"'\\\\]|\\\\.)*[\"']", scope: .string),
                PatternDefinition(name: "keyword", pattern: "\\b(and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|True|False|None|self|cls)\\b", scope: .keyword),
                PatternDefinition(name: "decorator", pattern: "@[a-zA-Z_][a-zA-Z0-9_]*", scope: .preprocessor),
                PatternDefinition(name: "function", pattern: "^\\s*(def)\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(", scope: .function, captureGroup: 2),
                PatternDefinition(name: "class", pattern: "^\\s*(class)\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*[:\\(]", scope: .type, captureGroup: 2),
                PatternDefinition(name: "number", pattern: "\\b(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?j?)\\b", scope: .number),
                PatternDefinition(name: "operator", pattern: "[+\\-*/%=<>!&|^~@:]", scope: .operator),
                PatternDefinition(name: "builtin", pattern: "\\b(print|len|range|int|str|float|list|dict|set|tuple|bool|type|isinstance|hasattr|getattr|setattr|input|open|file|map|filter|zip|enumerate|sorted|reversed|sum|min|max|abs|round|divmod|pow|hex|bin|oct|ord|chr|super|property|staticmethod|classmethod)\\b", scope: .type)
            ]
        )

        // JSON
        languageDefinitions[.json] = LanguageDefinition(
            name: "JSON",
            patterns: [
                PatternDefinition(name: "string.key", pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"\\s*:", scope: .variable),
                PatternDefinition(name: "string.value", pattern: ":\\s*\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", scope: .string),
                PatternDefinition(name: "string.bare", pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", scope: .string),
                PatternDefinition(name: "number", pattern: "-?\\b(?:0|[1-9]\\d*)(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", scope: .number),
                PatternDefinition(name: "keyword", pattern: "\\b(true|false|null)\\b", scope: .keyword),
                PatternDefinition(name: "operator", pattern: "[\\[\\]\\{\\}:,]", scope: .operator)
            ]
        )

        // YAML
        languageDefinitions[.yaml] = LanguageDefinition(
            name: "YAML",
            patterns: [
                PatternDefinition(name: "comment", pattern: "#.*$", scope: .comment),
                PatternDefinition(name: "key", pattern: "^\\s*[a-zA-Z_][a-zA-Z0-9_\\-\\.]*\\s*:", scope: .variable),
                PatternDefinition(name: "anchor", pattern: "&[a-zA-Z_][a-zA-Z0-9_]*", scope: .preprocessor),
                PatternDefinition(name: "alias", pattern: "\\*[a-zA-Z_][a-zA-Z0-9_]*", scope: .preprocessor),
                PatternDefinition(name: "tag", pattern: "![a-zA-Z!][a-zA-Z0-9!]*", scope: .type),
                PatternDefinition(name: "string.double", pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", scope: .string),
                PatternDefinition(name: "string.single", pattern: "'(?:[^'\\\\]|\\\\.)*'", scope: .string),
                PatternDefinition(name: "number", pattern: "\\b-?(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", scope: .number),
                PatternDefinition(name: "keyword", pattern: "\\b(true|false|null|yes|no|on|off|~)\\b", scope: .keyword),
                PatternDefinition(name: "operator", pattern: "[-|>:?!{}\\[\\],]", scope: .operator),
                PatternDefinition(name: "section", pattern: "^---$|^\\.\\.\\.\\s*$", scope: .preprocessor)
            ]
        )
    }

    func highlight(_ text: String, language: ProgrammingLanguage, theme: EditorTheme) -> NSAttributedString {
        // Defensive: handle empty or nil text
        guard !text.isEmpty else {
            return NSAttributedString(string: "")
        }

        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        // Base styling - get font size safely
        let fontSize = ThemeManager.shared.fontSize()
        let baseFont = ThemeManager.shared.editorFont(size: CGFloat(fontSize > 0 ? fontSize : 14.0))
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(theme.text),
            .font: baseFont
        ]
        attributedString.addAttributes(baseAttributes, range: fullRange)

        // Apply theme colors
        attributedString.addAttribute(.foregroundColor, value: NSColor(theme.text), range: fullRange)

        guard language != .plainText else {
            return attributedString
        }

        guard let definition = languageDefinitions[language] else {
            return attributedString
        }

        // Apply patterns with error handling
        for patternDef in definition.patterns {
            do {
                try applyPatternSafe(patternDef, to: attributedString, text: text, theme: theme)
            } catch {
                // Skip patterns that fail to compile
                print("Warning: Failed to apply pattern: \(patternDef.name)")
            }
        }

        return attributedString
    }

    /// Safe version of applyPattern with error handling
    private func applyPatternSafe(_ patternDef: PatternDefinition, to attributedString: NSMutableAttributedString, text: String, theme: EditorTheme) throws {
        guard let regex = try? NSRegularExpression(pattern: patternDef.pattern, options: patternDef.patternOptions) else {
            return // Silently skip invalid patterns
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)

        let color = colorForScope(patternDef.scope, theme: theme)
        let font = fontForScope(patternDef.scope, theme: theme)

        for match in matches {
            let matchRange: NSRange
            if patternDef.captureGroup > 0, match.numberOfRanges > patternDef.captureGroup {
                matchRange = match.range(at: patternDef.captureGroup)
            } else {
                matchRange = match.range
            }

            if matchRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
                if let font = font {
                    attributedString.addAttribute(.font, value: font, range: matchRange)
                }
            }
        }
    }

    func highlightAsync(_ text: String, language: ProgrammingLanguage, theme: EditorTheme, completion: @escaping (NSAttributedString) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            let result = self.highlight(text, language: language, theme: theme)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    // MARK: - Incremental Highlighting

    /// Highlights only the specified range (for incremental updates)
    /// Returns an attributed string with highlighting applied only to the given range
    func highlightRange(_ text: String, range: NSRange, language: ProgrammingLanguage, theme: EditorTheme) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        // Base styling
        let baseFont = ThemeManager.shared.editorFont(size: CGFloat(ThemeManager.shared.fontSize()))
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(theme.text),
            .font: baseFont
        ]
        attributedString.addAttributes(baseAttributes, range: fullRange)

        guard let definition = languageDefinitions[language], language != .plainText else {
            return attributedString
        }

        // Apply patterns only to the specified range
        for patternDef in definition.patterns {
            applyPattern(patternDef, to: attributedString, text: text, theme: theme, limitedTo: range)
        }

        return attributedString
    }

    /// Apply incremental highlighting to an existing attributed string
    /// Only re-highlights the specified line range
    func applyIncrementalHighlight(to textStorage: NSTextStorage, text: String, lineRange: NSRange, language: ProgrammingLanguage, theme: EditorTheme) {
        guard language != .plainText else { return }
        guard let definition = languageDefinitions[language] else { return }

        // Get the line text
        let nsText = text as NSString
        let lineString = nsText.substring(with: lineRange)

        // Reset the line to base styling first
        let baseFont = ThemeManager.shared.editorFont(size: CGFloat(ThemeManager.shared.fontSize()))
        let baseColor = NSColor(theme.text)
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: baseColor, range: lineRange)
        textStorage.addAttribute(.font, value: baseFont, range: lineRange)

        // Apply highlighting patterns to this line
        for patternDef in definition.patterns {
            applyPattern(patternDef, to: textStorage, text: text, theme: theme, limitedTo: lineRange)
        }
        textStorage.endEditing()
    }

    private func applyPattern(_ patternDef: PatternDefinition, to attributedString: NSMutableAttributedString, text: String, theme: EditorTheme) {
        guard let regex = try? NSRegularExpression(pattern: patternDef.pattern, options: patternDef.patternOptions) else {
            return
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)

        let color = colorForScope(patternDef.scope, theme: theme)
        let font = fontForScope(patternDef.scope, theme: theme)

        for match in matches {
            let matchRange: NSRange
            if patternDef.captureGroup > 0, match.numberOfRanges > patternDef.captureGroup {
                matchRange = match.range(at: patternDef.captureGroup)
            } else {
                matchRange = match.range
            }

            if matchRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
                if let font = font {
                    attributedString.addAttribute(.font, value: font, range: matchRange)
                }
            }
        }
    }

    /// Apply pattern only to a limited range (for incremental highlighting)
    private func applyPattern(_ patternDef: PatternDefinition, to attributedString: NSMutableAttributedString, text: String, theme: EditorTheme, limitedTo limitRange: NSRange) {
        guard let regex = try? NSRegularExpression(pattern: patternDef.pattern, options: patternDef.patternOptions) else {
            return
        }

        // Find matches within the limited range
        let matches = regex.matches(in: text, options: [], range: limitRange)

        let color = colorForScope(patternDef.scope, theme: theme)
        let font = fontForScope(patternDef.scope, theme: theme)

        for match in matches {
            let matchRange: NSRange
            if patternDef.captureGroup > 0, match.numberOfRanges > patternDef.captureGroup {
                matchRange = match.range(at: patternDef.captureGroup)
            } else {
                matchRange = match.range
            }

            if matchRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
                if let font = font {
                    attributedString.addAttribute(.font, value: font, range: matchRange)
                }
            }
        }
    }

    /// Apply pattern to NSTextStorage for incremental updates
    private func applyPattern(_ patternDef: PatternDefinition, to textStorage: NSTextStorage, text: String, theme: EditorTheme, limitedTo limitRange: NSRange) {
        guard let regex = try? NSRegularExpression(pattern: patternDef.pattern, options: patternDef.patternOptions) else {
            return
        }

        // Find matches within the limited range
        let matches = regex.matches(in: text, options: [], range: limitRange)

        let color = colorForScope(patternDef.scope, theme: theme)
        let font = fontForScope(patternDef.scope, theme: theme)

        for match in matches {
            let matchRange: NSRange
            if patternDef.captureGroup > 0, match.numberOfRanges > patternDef.captureGroup {
                matchRange = match.range(at: patternDef.captureGroup)
            } else {
                matchRange = match.range
            }

            if matchRange.location != NSNotFound {
                textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                if let font = font {
                    textStorage.addAttribute(.font, value: font, range: matchRange)
                }
            }
        }
    }

    private func colorForScope(_ scope: SyntaxScope, theme: EditorTheme) -> NSColor {
        switch scope {
        case .keyword: return NSColor(theme.keyword)
        case .string: return NSColor(theme.string)
        case .number: return NSColor(theme.number)
        case .comment: return NSColor(theme.comment)
        case .function: return NSColor(theme.function)
        case .type: return NSColor(theme.type)
        case .variable: return NSColor(theme.variable)
        case .operator: return NSColor(theme.`operator`)
        case .preprocessor: return NSColor(theme.preprocessor)
        }
    }

    private func fontForScope(_ scope: SyntaxScope, theme: EditorTheme) -> NSFont? {
        switch scope {
        case .keyword, .type, .function:
            let base = ThemeManager.shared.editorFont(size: CGFloat(ThemeManager.shared.fontSize()))
            return NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
        default:
            return nil
        }
    }

    // MARK: - Fold Region Detection

    func detectFoldRegions(in content: String, language: ProgrammingLanguage) -> [FoldRegion] {
        var regions: [FoldRegion] = []

        let lines = content.components(separatedBy: "\n")
        var stack: [(line: Int, indent: Int)] = []

        for (lineIndex, line) in lines.enumerated() {
            let currentLine = lineIndex + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count

            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("--") {
                continue
            }

            // Check for foldable keywords based on language
            let isFoldStart = isFoldStart(trimmedLine: trimmedLine, language: language)

            if isFoldStart {
                // Push to stack
                stack.append((line: currentLine, indent: indent))
            }

            // Check for fold end
            let isFoldEnd = isFoldEnd(trimmedLine: trimmedLine, language: language)

            if isFoldEnd {
                // Find matching start
                while let last = stack.popLast() {
                    if last.indent < indent {
                        // Found matching start
                        regions.append(FoldRegion(
                            startLine: last.line,
                            endLine: currentLine,
                            isFolded: false
                        ))
                        break
                    }
                }
            }
        }

        return regions
    }

    private func isFoldStart(trimmedLine: String, language: ProgrammingLanguage) -> Bool {
        switch language {
        case .python:
            // Function or class definitions
            let functionPattern = "^def\\s+[a-zA-Z_][a-zA-Z0-9_]*"
            let classPattern = "^class\\s+[a-zA-Z_][a-zA-Z0-9_]*"
            let tryPattern = "^try\\s*:"
            let exceptPattern = "^except\\s*:"
            let finallyPattern = "^finally\\s*:"
            let withPattern = "^with\\s+"
            let forPattern = "^for\\s+"
            let whilePattern = "^while\\s+"
            let ifPattern = "^if\\s+"
            let elifPattern = "^elif\\s+"
            let elsePattern = "^else\\s*:"

            return matchesPattern(trimmedLine, pattern: functionPattern) ||
                   matchesPattern(trimmedLine, pattern: classPattern) ||
                   matchesPattern(trimmedLine, pattern: tryPattern) ||
                   matchesPattern(trimmedLine, pattern: exceptPattern) ||
                   matchesPattern(trimmedLine, pattern: finallyPattern) ||
                   matchesPattern(trimmedLine, pattern: withPattern) ||
                   matchesPattern(trimmedLine, pattern: forPattern) ||
                   matchesPattern(trimmedLine, pattern: whilePattern) ||
                   matchesPattern(trimmedLine, pattern: ifPattern) ||
                   matchesPattern(trimmedLine, pattern: elifPattern) ||
                   matchesPattern(trimmedLine, pattern: elsePattern)

        case .shell:
            // Function definitions
            let functionPattern = "^[a-zA-Z_][a-zA-Z0-9_]*\\s*\\(\\)\\s*\\{"
            let ifPattern = "^if\\s+"
            let forPattern = "^for\\s+"
            let whilePattern = "^while\\s+"
            let casePattern = "^case\\s+"

            return matchesPattern(trimmedLine, pattern: functionPattern) ||
                   matchesPattern(trimmedLine, pattern: ifPattern) ||
                   matchesPattern(trimmedLine, pattern: forPattern) ||
                   matchesPattern(trimmedLine, pattern: whilePattern) ||
                   matchesPattern(trimmedLine, pattern: casePattern)

        case .sql:
            // BEGIN, CREATE, SELECT blocks
            let beginPattern = "^BEGIN\\s*$"
            let createPattern = "^CREATE\\s+(PROCEDURE|FUNCTION|TRIGGER|VIEW|TABLE)"
            let selectPattern = "^SELECT\\s+"

            return matchesPattern(trimmedLine, pattern: beginPattern, caseInsensitive: true) ||
                   matchesPattern(trimmedLine, pattern: createPattern, caseInsensitive: true) ||
                   matchesPattern(trimmedLine, pattern: selectPattern, caseInsensitive: true)

        case .json:
            return trimmedLine.hasSuffix("{") || trimmedLine.hasSuffix("[")

        case .yaml:
            return trimmedLine.hasSuffix(":") && !trimmedLine.hasPrefix("#")

        case .plainText:
            return false
        }
    }

    private func isFoldEnd(trimmedLine: String, language: ProgrammingLanguage) -> Bool {
        switch language {
        case .python:
            let endPattern = "^(return|break|continue|pass|raise|yield)\\b"
            return matchesPattern(trimmedLine, pattern: endPattern)

        case .shell:
            let fiPattern = "^fi\\s*$"
            let donePattern = "^done\\s*$"
            let esPattern = "^es\\s*$"
            let closeBrace = "^\\}"

            return matchesPattern(trimmedLine, pattern: fiPattern) ||
                   matchesPattern(trimmedLine, pattern: donePattern) ||
                   matchesPattern(trimmedLine, pattern: esPattern) ||
                   matchesPattern(trimmedLine, pattern: closeBrace)

        case .sql:
            let endPattern = "^END\\s*;?$"
            return matchesPattern(trimmedLine, pattern: endPattern, caseInsensitive: true)

        case .json:
            return trimmedLine == "}" || trimmedLine == "]" || trimmedLine == "}," || trimmedLine == "],"

        case .yaml:
            return false

        case .plainText:
            return false
        }
    }

    private func matchesPattern(_ string: String, pattern: String, caseInsensitive: Bool = false) -> Bool {
        var options: NSRegularExpression.Options = [.anchorsMatchLines]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }

        let range = NSRange(location: 0, length: string.utf16.count)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }
}

struct LanguageDefinition {
    let name: String
    let patterns: [PatternDefinition]
}

struct PatternDefinition {
    let name: String
    let pattern: String
    let scope: SyntaxScope
    var captureGroup: Int = 0

    var patternOptions: NSRegularExpression.Options {
        var options: NSRegularExpression.Options = [.anchorsMatchLines]
        if scope == .comment && (name.contains("multi") || name.contains("single")) {
            options = []
        }
        return options
    }
}

enum SyntaxScope {
    case keyword
    case string
    case number
    case comment
    case function
    case type
    case variable
    case `operator`
    case preprocessor
}
