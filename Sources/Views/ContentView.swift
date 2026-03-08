import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = EditorViewModel()
    @State private var showFindBar = false
    @State private var showSidebar = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolbarView(viewModel: viewModel, showFindBar: $showFindBar, showSidebar: $showSidebar, themeManager: themeManager)

            // Main content - simplified
            SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Status bar
            StatusBarView(viewModel: viewModel, themeManager: themeManager)
        }
        .background(Color(themeManager.currentTheme.background))
        .onAppear {
            setupNotifications()
        }
        .sheet(isPresented: $showFindBar) {
            FindBarView(viewModel: viewModel, isPresented: $showFindBar, themeManager: themeManager)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .newDocument, object: nil, queue: .main) { _ in
            viewModel.newDocument()
        }

        NotificationCenter.default.addObserver(forName: .openDocument, object: nil, queue: .main) { _ in
            viewModel.openDocument()
        }

        NotificationCenter.default.addObserver(forName: .saveDocument, object: nil, queue: .main) { _ in
            viewModel.saveDocument()
        }

        NotificationCenter.default.addObserver(forName: .saveDocumentAs, object: nil, queue: .main) { _ in
            viewModel.saveDocumentAs()
        }
    }
}
