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
    }

    func highlight(_ text: String, language: ProgrammingLanguage, theme: EditorTheme) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        // Base styling
        let baseFont = NSFont.monospacedSystemFont(ofSize: ThemeManager.shared.fontSize(), weight: .regular)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(theme.text),
            .font: baseFont
        ]
        attributedString.addAttributes(baseAttributes, range: fullRange)

        // Apply theme colors
        attributedString.addAttribute(.foregroundColor, value: NSColor(theme.text), range: fullRange)

        guard let definition = languageDefinitions[language], language != .plainText else {
            return attributedString
        }

        // Apply patterns
        for patternDef in definition.patterns {
            applyPattern(patternDef, to: attributedString, text: text, theme: theme)
        }

        return attributedString
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
        let baseSize = ThemeManager.shared.fontSize()
        switch scope {
        case .keyword, .type:
            return NSFont.monospacedSystemFont(ofSize: baseSize, weight: .semibold)
        case .function:
            return NSFont.monospacedSystemFont(ofSize: baseSize, weight: .medium)
        default:
            return nil
        }
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
