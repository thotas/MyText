import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: EditorViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(Color(themeManager.currentTheme.comment))
                Text("Document")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(themeManager.currentTheme.text))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(themeManager.currentTheme.toolbar))

            Divider()
                .background(Color(themeManager.currentTheme.lineNumber).opacity(0.3))

            // File info
            VStack(alignment: .leading, spacing: 12) {
                SidebarItem(icon: "doc", title: "File", value: viewModel.document.fileName)
                SidebarItem(icon: "chevron.left.forwardslash.chevron.right", title: "Language", value: viewModel.detectedLanguage.displayName)
                SidebarItem(icon: "number", title: "Lines", value: "\(viewModel.document.content.components(separatedBy: "\n").count)")
                SidebarItem(icon: "character.cursor.ibeam", title: "Characters", value: "\(viewModel.document.content.count)")
            }
            .padding(12)

            Spacer()

            // Syntax highlighting toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("SYNTAX HIGHLIGHTING")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(themeManager.currentTheme.comment))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                ForEach(ProgrammingLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        // Language is auto-detected, but this shows available options
                    }) {
                        HStack {
                            Image(systemName: viewModel.detectedLanguage == language ? "circle.fill" : "circle")
                                .font(.system(size: 8))
                                .foregroundColor(viewModel.detectedLanguage == language ? Color(themeManager.currentTheme.keyword) : Color(themeManager.currentTheme.lineNumber))

                            Text(language.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(Color(themeManager.currentTheme.text))

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color(themeManager.currentTheme.background))
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let value: String

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(themeManager.currentTheme.comment))
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(themeManager.currentTheme.comment))

            Spacer()

            Text(value)
                .font(.system(size: 12))
                .foregroundColor(Color(themeManager.currentTheme.text))
                .lineLimit(1)
        }
    }
}
