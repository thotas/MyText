import SwiftUI

struct TabItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var document: TextDocument
    var isModified: Bool

    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct TabBarView: View {
    @Binding var tabs: [TabItem]
    @Binding var selectedTab: TabItem?
    @ObservedObject var themeManager = ThemeManager.shared
    var onTabClose: ((TabItem) -> Void)?
    var onSelectionChange: ((TabItem?) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach($tabs) { $tab in
                    TabItemView(
                        tab: $tab,
                        isSelected: selectedTab?.id == tab.id,
                        themeManager: themeManager,
                        onSelect: {
                            selectedTab = tab
                            onSelectionChange?(tab)
                        },
                        onClose: {
                            onTabClose?(tab)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .background(Color(themeManager.currentTheme.background).opacity(0.95))
    }
}

struct TabItemView: View {
    @Binding var tab: TabItem
    let isSelected: Bool
    @ObservedObject var themeManager: ThemeManager
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Modified indicator
            if tab.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }

            // Tab title
            Text(tab.title)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? Color(themeManager.currentTheme.text) : Color(themeManager.currentTheme.text).opacity(0.7))
                .lineLimit(1)

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(themeManager.currentTheme.text).opacity(0.6))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(themeManager.currentTheme.background) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
