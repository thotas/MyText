import SwiftUI

struct SettingsView: View {
    @State private var fontSize: Double = ThemeManager.shared.fontSize()
    @State private var tabWidth: Int = ThemeManager.shared.tabWidth()
    @State private var showLineNumbers: Bool = ThemeManager.shared.showLineNumbers()
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        TabView {
            // Appearance tab
            Form {
                Section("Theme") {
                    Picker("Color Theme", selection: Binding(
                        get: { themeManager.currentTheme.name },
                        set: { name in
                            if let theme = themeManager.themes.first(where: { $0.name == name }) {
                                themeManager.setTheme(theme)
                            }
                        }
                    )) {
                        ForEach(themeManager.themes) { theme in
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
                    .pickerStyle(.menu)
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
                }
            }
            .padding()
            .tabItem {
                Label("Editor", systemImage: "doc.text")
            }
        }
        .frame(width: 450, height: 300)
        .preferredColorScheme(.dark)
    }
}
