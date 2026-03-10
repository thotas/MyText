import SwiftUI

struct QuickOpenView: View {
    @Binding var isPresented: Bool
    @ObservedObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @State private var recentFiles: [URL] = []

    var filteredFiles: [URL] {
        if searchText.isEmpty {
            return recentFiles
        }
        return recentFiles.filter { url in
            url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Quick Open", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit {
                        selectFile()
                    }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(themeManager.currentTheme.editorBackground))

            Divider()

            // Results list
            if filteredFiles.isEmpty {
                Text(searchText.isEmpty ? "No recent files" : "No matching files")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    List(0..<filteredFiles.count, id: \.self) { index in
                        Button(action: { selectFile(at: index) }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(Color(themeManager.currentTheme.keyword))
                                VStack(alignment: .leading) {
                                    Text(filteredFiles[index].lastPathComponent)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(themeManager.currentTheme.text))
                                    Text(filteredFiles[index].deletingLastPathComponent().path)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(themeManager.currentTheme.comment))
                                }
                                Spacer()
                                if index == selectedIndex {
                                    Image(systemName: "return")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(index == selectedIndex ? Color.accentColor.opacity(0.3) : Color.clear)
                        .id(index)
                    }
                    .listStyle(.plain)
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 300)
        .background(Color(themeManager.currentTheme.background))
        .onAppear {
            recentFiles = themeManager.recentFiles()
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredFiles.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private func selectFile(at index: Int? = nil) {
        let idx = index ?? selectedIndex
        guard idx < filteredFiles.count else { return }

        NotificationCenter.default.post(name: .openRecentFile, object: filteredFiles[idx])
        isPresented = false
    }
}
