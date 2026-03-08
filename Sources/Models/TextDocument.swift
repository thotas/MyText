import Foundation
import SwiftUI

struct TextDocument: Identifiable, Equatable {
    let id = UUID()
    var content: String
    var fileURL: URL?
    var isModified: Bool = false
    var encoding: String.Encoding = .utf8
    var lineEnding: LineEnding = .unix

    var fileName: String {
        if let url = fileURL {
            return url.lastPathComponent
        }
        return "Untitled"
    }

    var fileExtension: String {
        if let url = fileURL {
            return url.pathExtension.lowercased()
        }
        return ""
    }

    enum LineEnding: String, CaseIterable {
        case unix = "\n"
        case windows = "\r\n"
        case mac = "\r"

        var displayName: String {
            switch self {
            case .unix: return "Unix (LF)"
            case .windows: return "Windows (CRLF)"
            case .mac: return "Classic Mac (CR)"
            }
        }
    }

    static func == (lhs: TextDocument, rhs: TextDocument) -> Bool {
        lhs.id == rhs.id
    }
}

struct EditorState {
    var cursorPosition: Int = 0
    var selectionStart: Int?
    var selectionEnd: Int?
    var scrollOffset: CGPoint = .zero
    var lineNumber: Int = 1
    var columnNumber: Int = 1

    var hasSelection: Bool {
        selectionStart != nil && selectionEnd != nil
    }
}

struct RecentFile: Codable, Identifiable {
    let id: UUID
    let url: URL
    let lastOpened: Date

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.lastOpened = Date()
    }
}
