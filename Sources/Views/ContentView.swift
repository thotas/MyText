import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = EditorViewModel()
    @State private var showFindBar = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolbarView(viewModel: viewModel, showFindBar: $showFindBar)
                .environmentObject(themeManager)

            // Main content
            HSplitView {
                // Sidebar (optional)
                if viewModel.showSidebar {
                    SidebarView(viewModel: viewModel)
                        .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
                }

                // Editor
                EditorView(viewModel: viewModel)
                    .environmentObject(themeManager)
            }

            // Status bar
            StatusBarView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .background(Color(themeManager.currentTheme.background))
        .onAppear {
            setupNotifications()
        }
        .sheet(isPresented: $showFindBar) {
            FindBarView(viewModel: viewModel, isPresented: $showFindBar)
                .environmentObject(themeManager)
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
