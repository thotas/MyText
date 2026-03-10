import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = EditorViewModel()
    @State private var showFindBar = false
    @State private var showSidebar = true

    // Store notification observers to remove them later
    @State private var notificationObservers: [NSObjectProtocol] = []

    var body: some View {
        HSplitView {
            // Sidebar
            if showSidebar {
                SidebarView(viewModel: viewModel, themeManager: themeManager)
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
            }

            // Main content
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(viewModel: viewModel, showFindBar: $showFindBar, showSidebar: $showSidebar, themeManager: themeManager)

                // Editor
                SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Status bar
                StatusBarView(viewModel: viewModel, themeManager: themeManager)
            }
        }
        .background(Color(themeManager.currentTheme.background))
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotificationObservers()
        }
        .sheet(isPresented: $showFindBar) {
            FindBarView(viewModel: viewModel, isPresented: $showFindBar, themeManager: themeManager)
        }
    }

    private func setupNotifications() {
        let observer1 = NotificationCenter.default.addObserver(forName: .newDocument, object: nil, queue: .main) { _ in
            viewModel.newDocument()
        }

        let observer2 = NotificationCenter.default.addObserver(forName: .openDocument, object: nil, queue: .main) { _ in
            viewModel.openDocument()
        }

        let observer3 = NotificationCenter.default.addObserver(forName: .saveDocument, object: nil, queue: .main) { _ in
            viewModel.saveDocument()
        }

        let observer4 = NotificationCenter.default.addObserver(forName: .saveDocumentAs, object: nil, queue: .main) { _ in
            viewModel.saveDocumentAs()
        }

        let observer5 = NotificationCenter.default.addObserver(forName: .openRecentFile, object: nil, queue: .main) { notification in
            if let url = notification.object as? URL {
                viewModel.loadDocument(from: url)
            }
        }

        notificationObservers = [observer1, observer2, observer3, observer4, observer5]
    }

    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers = []
    }
}
