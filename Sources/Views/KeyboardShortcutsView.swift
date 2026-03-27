import SwiftUI

struct KeyboardShortcutsView: View {
    @Binding var isPresented: Bool

    private let sections: [(String, [(String, String)])] = [
        ("File", [
            ("New", "⌘N"),
            ("New Tab", "⌘T"),
            ("Open…", "⌘O"),
            ("Quick Open", "⌘P"),
            ("Save", "⌘S"),
            ("Save As…", "⇧⌘S"),
            ("Close Tab", "⌘W"),
        ]),
        ("Edit", [
            ("Duplicate Line", "⌘D"),
            ("Move Line Up", "⇧⌘↑"),
            ("Move Line Down", "⇧⌘↓"),
            ("Toggle Comment", "⌘/"),
            ("Select Line", "⇧⌘L"),
            ("Select All Occurrences", "⌥⌘L"),
            ("Uppercase", "⇧⌘U"),
            ("Lowercase", "⇧⌥⌘U"),
            ("Join Lines", "⌥⌘J"),
            ("Jump to Matching Bracket", "⇧⌘M"),
            ("Trim Trailing Whitespace", "⇧⌥⌘T"),
        ]),
        ("View", [
            ("Zoom In", "⌘+"),
            ("Zoom Out", "⌘-"),
            ("Reset Zoom", "⌘0"),
            ("Show Invisibles", "⇧⌘I"),
            ("Next Tab", "⇧⌘]"),
            ("Previous Tab", "⇧⌘["),
            ("Distraction-Free Mode", "⇧⌘F"),
        ]),
        ("Find", [
            ("Find…", "⌘F"),
            ("Find Selection", "⌘E"),
            ("Find Next", "⌘G"),
            ("Find Previous", "⇧⌘G"),
            ("Go to Line…", "⌘L"),
        ]),
        ("Help", [
            ("Keyboard Shortcuts", "⌘?"),
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(sections, id: \.0) { section in
                        Section(header: sectionHeader(section.0)) {
                            ForEach(section.1, id: \.0) { item in
                                shortcutRow(item.0, shortcut: item.1)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 360, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.windowBackgroundColor))
    }

    private func shortcutRow(_ action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Spacer()
            Text(shortcut)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}
