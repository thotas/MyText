import SwiftUI
import UniformTypeIdentifiers

@main
struct MyTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var recentFiles: [URL] {
        ThemeManager.shared.recentFiles()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Handle files opened from Finder
                    NotificationCenter.default.post(name: .openFileFromURL, object: url)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Quick Open") {
                    NotificationCenter.default.post(name: .quickOpen, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)

                Divider()

                Menu("Recent Files") {
                    ForEach(recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            NotificationCenter.default.post(name: .openRecentFile, object: url)
                        }
                    }
                }
                .disabled(recentFiles.isEmpty)

                Divider()

                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Trim Trailing Whitespace") {
                    NotificationCenter.default.post(name: .trimTrailingWhitespace, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift, .option])

                Menu("Convert Indentation") {
                    Button("Convert to Spaces") {
                        NotificationCenter.default.post(name: .convertToSpaces, object: nil)
                    }
                    .keyboardShortcut("\\", modifiers: [.command, .shift])

                    Button("Convert to Tabs") {
                        NotificationCenter.default.post(name: .convertToTabs, object: nil)
                    }
                    .keyboardShortcut("\\", modifiers: [.command, .option])
                }

                Menu("Convert Line Endings") {
                    Button("Convert to LF (Unix)") {
                        NotificationCenter.default.post(name: .convertToLF, object: nil)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift, .option])

                    Button("Convert to CRLF (Windows)") {
                        NotificationCenter.default.post(name: .convertToCRLF, object: nil)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .option, .control])

                    Button("Convert to CR (Classic Mac)") {
                        NotificationCenter.default.post(name: .convertToCR, object: nil)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .control])
                }

                Divider()

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Divider()
                Button("Show Next Tab") {
                    NotificationCenter.default.post(name: .nextTab, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: .command)
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Show Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command, .shift])
                .keyboardShortcut("[", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Divider()
                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Button("Duplicate Line") {
                    NotificationCenter.default.post(name: .duplicateLine, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Move Line Up") {
                    NotificationCenter.default.post(name: .moveLineUp, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .shift])

                Button("Move Line Down") {
                    NotificationCenter.default.post(name: .moveLineDown, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .shift])

                Button("Toggle Comment") {
                    NotificationCenter.default.post(name: .toggleComment, object: nil)
                }
                .keyboardShortcut("/", modifiers: .command)

                Button("Jump to Matching Bracket") {
                    NotificationCenter.default.post(name: .jumpToMatchingBracket, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Button("Select All Occurrences") {
                    NotificationCenter.default.post(name: .selectAllOccurrences, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .option])

                Button("Select Line") {
                    NotificationCenter.default.post(name: .selectLine, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])

                Divider()

                Button("Uppercase Selection") {
                    NotificationCenter.default.post(name: .uppercaseSelection, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Button("Lowercase Selection") {
                    NotificationCenter.default.post(name: .lowercaseSelection, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command, .option, .shift])

                Button("Sort Lines") {
                    NotificationCenter.default.post(name: .sortLines, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Divider()

                Button("Go to Line...") {
                    NotificationCenter.default.post(name: .goToLine, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)

                Divider()

                Button("Toggle Fold") {
                    NotificationCenter.default.post(name: .toggleFold, object: nil)
                }
                .keyboardShortcut("\\", modifiers: .command)

                Button("Fold All") {
                    NotificationCenter.default.post(name: .foldAll, object: nil)
                }
                .keyboardShortcut("0", modifiers: [.command, .option])

                Button("Unfold All") {
                    NotificationCenter.default.post(name: .unfoldAll, object: nil)
                }
                .keyboardShortcut("=", modifiers: [.command, .option])

                Divider()

                Button("Show Invisibles") {
                    NotificationCenter.default.post(name: .toggleInvisibles, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Auto-Pair Brackets") {
                    NotificationCenter.default.post(name: .toggleAutoPairBrackets, object: nil)
                }

                Button("Show Line Length Guide") {
                    NotificationCenter.default.post(name: .toggleLineLengthGuide, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Split Horizontal") {
                    NotificationCenter.default.post(name: .splitHorizontal, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Button("Split Vertical") {
                    NotificationCenter.default.post(name: .splitVertical, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .option])

                Button("Close Split") {
                    NotificationCenter.default.post(name: .splitClose, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .option])

                Divider()

                Button("Zoom In") {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    NotificationCenter.default.post(name: .zoomReset, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button("Find...") {
                    NotificationCenter.default.post(name: .findNext, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Selection") {
                    NotificationCenter.default.post(name: .findSelection, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Find Next") {
                    NotificationCenter.default.post(name: .findNext, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    NotificationCenter.default.post(name: .findPrevious, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Go to Line...") {
                    NotificationCenter.default.post(name: .goToLine, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let openFileFromURL = Notification.Name("openFileFromURL")
    static let quickOpen = Notification.Name("quickOpen")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let openRecentFile = Notification.Name("openRecentFile")
    static let duplicateLine = Notification.Name("duplicateLine")
    static let moveLineUp = Notification.Name("moveLineUp")
    static let moveLineDown = Notification.Name("moveLineDown")
    static let toggleComment = Notification.Name("toggleComment")
    static let selectLine = Notification.Name("selectLine")
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let nextTab = Notification.Name("nextTab")
    static let previousTab = Notification.Name("previousTab")
    static let foldStateChanged = Notification.Name("foldStateChanged")
    static let toggleFold = Notification.Name("toggleFold")
    static let foldAll = Notification.Name("foldAll")
    static let unfoldAll = Notification.Name("unfoldAll")
    static let goToLine = Notification.Name("goToLine")
    static let findNext = Notification.Name("findNext")
    static let findPrevious = Notification.Name("findPrevious")
    static let splitHorizontal = Notification.Name("splitHorizontal")
    static let splitVertical = Notification.Name("splitVertical")
    static let splitClose = Notification.Name("splitClose")
    static let uppercaseSelection = Notification.Name("uppercaseSelection")
    static let lowercaseSelection = Notification.Name("lowercaseSelection")
    static let sortLines = Notification.Name("sortLines")
    static let toggleInvisibles = Notification.Name("toggleInvisibles")
    static let toggleAutoPairBrackets = Notification.Name("toggleAutoPairBrackets")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let zoomReset = Notification.Name("zoomReset")
    static let toggleLineLengthGuide = Notification.Name("toggleLineLengthGuide")
    static let refreshEditor = Notification.Name("refreshEditor")
    static let trimTrailingWhitespace = Notification.Name("trimTrailingWhitespace")
    static let findSelection = Notification.Name("findSelection")
    static let convertToSpaces = Notification.Name("convertToSpaces")
    static let convertToTabs = Notification.Name("convertToTabs")
    static let convertToLF = Notification.Name("convertToLF")
    static let convertToCRLF = Notification.Name("convertToCRLF")
    static let convertToCR = Notification.Name("convertToCR")
    static let jumpToMatchingBracket = Notification.Name("jumpToMatchingBracket")
    static let selectAllOccurrences = Notification.Name("selectAllOccurrences")
}
