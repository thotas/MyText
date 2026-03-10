import SwiftUI

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

                Button("Show Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command, .shift])
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
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let openRecentFile = Notification.Name("openRecentFile")
    static let duplicateLine = Notification.Name("duplicateLine")
    static let moveLineUp = Notification.Name("moveLineUp")
    static let moveLineDown = Notification.Name("moveLineDown")
    static let toggleComment = Notification.Name("toggleComment")
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let nextTab = Notification.Name("nextTab")
    static let previousTab = Notification.Name("previousTab")
}
