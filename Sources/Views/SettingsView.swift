import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var fontSize: Double = ThemeManager.shared.fontSize()
    @State private var tabWidth: Int = ThemeManager.shared.tabWidth()
    @State private var showLineNumbers: Bool = ThemeManager.shared.showLineNumbers()
    @State private var showInvisibles: Bool = ThemeManager.shared.showInvisibles()
    @State private var highlightTrailingWhitespace: Bool = ThemeManager.shared.highlightTrailingWhitespace()
    @State private var autoSaveEnabled: Bool = ThemeManager.shared.autoSaveEnabled()
    @State private var showLineLengthGuide: Bool = ThemeManager.shared.showLineLengthGuide()
    @State private var lineLengthGuideColumn: Double = Double(ThemeManager.shared.lineLengthGuideColumn())
    @State private var trimTrailingWhitespace: Bool = UserDefaults.standard.bool(forKey: "trimTrailingWhitespace")
    @State private var showSaveThemeSheet: Bool = false
    @State private var newThemeName: String = ""
    @State private var showImportError: Bool = false
    @State private var importErrorMessage: String = ""
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        TabView {
            // Appearance tab
            Form {
                Section("Theme") {
                    Toggle("Sync with System Appearance", isOn: $themeManager.syncWithSystem)
                        .onChange(of: themeManager.syncWithSystem) { _, _ in
                            // ThemeManager handles the change
                        }

                    Picker("Color Theme", selection: Binding(
                        get: { themeManager.currentTheme.name },
                        set: { name in
                            // Disable sync when manually selecting a theme
                            if themeManager.syncWithSystem {
                                themeManager.syncWithSystem = false
                            }
                            if let theme = themeManager.themes.first(where: { $0.name == name }) {
                                themeManager.setTheme(theme)
                            }
                        }
                    )) {
                        Section("Built-in") {
                            ForEach(themeManager.builtInThemes) { theme in
                                HStack {
                                    Circle()
                                        .fill(Color(theme.background))
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(theme.keyword), lineWidth: 2)
                                        )
                                    Text(theme.name)
                                }
                                .tag(theme.name)
                            }
                        }

                        if !themeManager.customThemes.isEmpty {
                            Section("Custom") {
                                ForEach(themeManager.customThemes) { theme in
                                    HStack {
                                        Circle()
                                            .fill(Color(theme.background))
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color(theme.keyword), lineWidth: 2)
                                            )
                                        Text(theme.name)
                                    }
                                    .tag(theme.name)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(themeManager.syncWithSystem)
                    .opacity(themeManager.syncWithSystem ? 0.5 : 1.0)

                    HStack {
                        Button("Save Current Theme...") {
                            newThemeName = themeManager.currentTheme.name
                            showSaveThemeSheet = true
                        }
                        .disabled(themeManager.customThemes.contains(where: { $0.name == themeManager.currentTheme.name }))

                        Spacer()

                        Button("Import Theme...") {
                            importTheme()
                        }

                        if !themeManager.customThemes.isEmpty {
                            Button("Delete Custom...") {
                                if let customTheme = themeManager.customThemes.first(where: { $0.name == themeManager.currentTheme.name }) {
                                    themeManager.deleteCustomTheme(customTheme)
                                    if themeManager.customThemes.isEmpty {
                                        themeManager.setTheme(EditorTheme.dark)
                                    } else {
                                        themeManager.setTheme(themeManager.customThemes[0])
                                    }
                                }
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }

                Section("Font") {
                    HStack {
                        Text("Font Size:")
                        Slider(value: $fontSize, in: 10...24, step: 1) {
                            Text("Font Size")
                        }
                        .onChange(of: fontSize) { _, newValue in
                            themeManager.setFontSize(newValue)
                        }
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 40)
                    }

                    Text("Font: SF Mono (System)")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }

            // Editor tab
            Form {
                Section("Indentation") {
                    Stepper("Tab Width: \(tabWidth) spaces", value: $tabWidth, in: 2...8, step: 1)
                        .onChange(of: tabWidth) { _, newValue in
                            themeManager.setTabWidth(newValue)
                        }

                    Text("Uses spaces instead of tabs")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Display") {
                    Toggle("Show Line Numbers", isOn: $showLineNumbers)
                        .onChange(of: showLineNumbers) { _, newValue in
                            themeManager.setShowLineNumbers(newValue)
                        }

                    Toggle("Show Invisibles", isOn: $showInvisibles)
                        .onChange(of: showInvisibles) { _, newValue in
                            themeManager.setShowInvisibles(newValue)
                        }

                    Toggle("Highlight Trailing Whitespace", isOn: $highlightTrailingWhitespace)
                        .onChange(of: highlightTrailingWhitespace) { _, newValue in
                            themeManager.setHighlightTrailingWhitespace(newValue)
                        }

                    Toggle("Line Length Guide", isOn: $showLineLengthGuide)
                        .onChange(of: showLineLengthGuide) { _, newValue in
                            themeManager.setShowLineLengthGuide(newValue)
                        }

                    if showLineLengthGuide {
                        HStack {
                            Text("Column:")
                                .font(.system(size: 12))
                            Slider(value: $lineLengthGuideColumn, in: 40...200, step: 10)
                                .onChange(of: lineLengthGuideColumn) { _, newValue in
                                    themeManager.setLineLengthGuideColumn(Int(newValue))
                                }
                            Text("\(Int(lineLengthGuideColumn))")
                                .font(.system(size: 12))
                                .frame(width: 30)
                        }
                    }
                }

                Section("Save") {
                    Toggle("Auto-save", isOn: $autoSaveEnabled)
                        .onChange(of: autoSaveEnabled) { _, newValue in
                            themeManager.setAutoSaveEnabled(newValue)
                        }

                    Toggle("Trim Trailing Whitespace on Save", isOn: $trimTrailingWhitespace)
                        .onChange(of: trimTrailingWhitespace) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "trimTrailingWhitespace")
                        }
                }
            }
            .padding()
            .tabItem {
                Label("Editor", systemImage: "doc.text")
            }
        }
        .frame(width: 450, height: 350)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSaveThemeSheet) {
            VStack(spacing: 20) {
                Text("Save Custom Theme")
                    .font(.headline)

                TextField("Theme Name", text: $newThemeName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)

                HStack(spacing: 20) {
                    Button("Cancel") {
                        showSaveThemeSheet = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Save") {
                        if !newThemeName.isEmpty {
                            themeManager.saveCustomTheme(themeManager.currentTheme, name: newThemeName)
                            showSaveThemeSheet = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newThemeName.isEmpty)
                }
            }
            .padding(30)
            .frame(width: 320, height: 150)
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try themeManager.importTheme(from: url)
                // Switch to the newly imported theme
                if let customTheme = themeManager.customThemes.last {
                    themeManager.setTheme(customTheme)
                }
            } catch {
                importErrorMessage = error.localizedDescription
                showImportError = true
            }
        }
    }
}
