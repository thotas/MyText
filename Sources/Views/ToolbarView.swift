import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Binding var showFindBar: Bool
    @Binding var showSidebar: Bool
    var themeManager: ThemeManager
    @State private var showingThemePicker = false

    var body: some View {
        HStack(spacing: 12) {
            // Left toolbar items
            HStack(spacing: 8) {
                ToolbarButton(icon: "doc.badge.plus", tooltip: "New", themeManager: themeManager) {
                    viewModel.newDocument()
                }

                ToolbarButton(icon: "folder", tooltip: "Open", themeManager: themeManager) {
                    viewModel.openDocument()
                }

                ToolbarButton(icon: "square.and.arrow.down", tooltip: "Save", themeManager: themeManager) {
                    viewModel.saveDocument()
                }
                .disabled(!viewModel.document.isModified)
            }

            Divider()
                .frame(height: 20)

            // Center - document title
            Text(viewModel.document.fileName + (viewModel.document.isModified ? " *" : ""))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(themeManager.currentTheme.text))
                .lineLimit(1)

            Spacer()

            // Right toolbar items
            HStack(spacing: 8) {
                ToolbarButton(icon: "sidebar.left", tooltip: "Toggle Sidebar", themeManager: themeManager) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSidebar.toggle()
                    }
                }

                ToolbarButton(icon: "magnifyingglass", tooltip: "Find (Cmd+F)", themeManager: themeManager) {
                    showFindBar = true
                }

                Menu {
                    ForEach(themeManager.themes) { theme in
                        Button(action: {
                            themeManager.setTheme(theme)
                        }) {
                            HStack {
                                Text(theme.name)
                                if theme.name == themeManager.currentTheme.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Settings...") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                } label: {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 14))
                        .foregroundColor(Color(themeManager.currentTheme.text))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28, height: 22)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(themeManager.currentTheme.toolbar))
    }
}

struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    var themeManager: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(themeManager.currentTheme.text))
                .frame(width: 28, height: 22)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
