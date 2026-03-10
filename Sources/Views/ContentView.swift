import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = EditorViewModel()
    @State private var showFindBar = false
    @State private var showSidebar = true
    @State private var tabs: [TabItem] = []
    @State private var selectedTab: TabItem?

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
                // Tab bar (show when multiple tabs)
                if tabs.count > 1 {
                    TabBarView(
                        tabs: $tabs,
                        selectedTab: $selectedTab,
                        onTabClose: { tab in
                            self.closeTab(tab)
                        },
                        onSelectionChange: { tab in
                            if let tab = tab {
                                self.viewModel.document = tab.document
                            }
                        }
                    )
                }

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
            // Create initial tab
            createNewTab()
        }
        .onDisappear {
            removeNotificationObservers()
        }
        .sheet(isPresented: $showFindBar) {
            FindBarView(viewModel: viewModel, isPresented: $showFindBar, themeManager: themeManager)
        }
    }

    private func createNewTab() {
        let newDoc = TextDocument(content: "")
        let tabItem = TabItem(title: newDoc.fileName, document: newDoc, isModified: false)
        tabs.append(tabItem)
        selectedTab = tabItem
    }

    private func selectNextTab() {
        guard let current = selectedTab, tabs.count > 1 else { return }
        if let index = tabs.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (index + 1) % tabs.count
            selectedTab = tabs[nextIndex]
        }
    }

    private func selectPreviousTab() {
        guard let current = selectedTab, tabs.count > 1 else { return }
        if let index = tabs.firstIndex(where: { $0.id == current.id }) {
            let prevIndex = (index - 1 + tabs.count) % tabs.count
            selectedTab = tabs[prevIndex]
        }
    }

    private func closeCurrentTab() {
        guard let current = selectedTab else { return }
        closeTab(current)
    }

    private func closeTab(_ tab: TabItem) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }

        tabs.remove(at: index)

        if selectedTab?.id == tab.id {
            if tabs.isEmpty {
                // Create a new tab FIRST, then assign to selectedTab
                let newDoc = TextDocument(content: "")
                let newTab = TabItem(title: newDoc.fileName, document: newDoc, isModified: false)
                tabs.append(newTab)
                selectedTab = newTab
                viewModel.document = newDoc
            } else if index >= tabs.count {
                selectedTab = tabs.last
                if let selected = selectedTab {
                    viewModel.document = selected.document
                }
            } else {
                selectedTab = tabs[index]
                if let selected = selectedTab {
                    viewModel.document = selected.document
                }
            }
        }
    }

    private func setupNotifications() {
        let observer1 = NotificationCenter.default.addObserver(forName: .newDocument, object: nil, queue: .main) { _ in
            // Create new tab instead of just new document
            let newDoc = TextDocument(content: "")
            let tabItem = TabItem(title: newDoc.fileName, document: newDoc, isModified: false)
            self.tabs.append(tabItem)
            self.selectedTab = tabItem
            self.viewModel.document = newDoc
            self.viewModel.editorState = EditorState()
        }

        // Handle files opened from Finder (double-click)
        let observerOpenFile = NotificationCenter.default.addObserver(forName: .openFileFromURL, object: nil, queue: .main) { notification in
            if let url = notification.object as? URL {
                self.viewModel.loadDocument(from: url)
                let tabItem = TabItem(title: self.viewModel.document.fileName, document: self.viewModel.document, isModified: false)
                self.tabs.append(tabItem)
                self.selectedTab = tabItem
                self.viewModel.document = tabItem.document
            }
        }

        let observer2 = NotificationCenter.default.addObserver(forName: .openDocument, object: nil, queue: .main) { _ in
            self.viewModel.openDocument()
            // If file was loaded, create a new tab for it
            // Sync the document to ensure editor gets updated content
            if let url = self.viewModel.document.fileURL {
                let tabItem = TabItem(title: self.viewModel.document.fileName, document: self.viewModel.document, isModified: false)
                self.tabs.append(tabItem)
                self.selectedTab = tabItem
                // Force sync to ensure SimpleTextEditor updates
                self.viewModel.document = tabItem.document
            }
        }

        let observer3 = NotificationCenter.default.addObserver(forName: .saveDocument, object: nil, queue: .main) { _ in
            self.viewModel.saveDocument()
            // Update tab title if saved to a new file
            if let selected = self.selectedTab,
               let index = self.tabs.firstIndex(where: { $0.id == selected.id }) {
                self.tabs[index].title = self.viewModel.document.fileName
                self.tabs[index].document = self.viewModel.document
                self.tabs[index].isModified = false
            }
        }

        let observer4 = NotificationCenter.default.addObserver(forName: .saveDocumentAs, object: nil, queue: .main) { _ in
            self.viewModel.saveDocumentAs()
            // Update tab title after Save As
            if let selected = self.selectedTab,
               let index = self.tabs.firstIndex(where: { $0.id == selected.id }) {
                self.tabs[index].title = self.viewModel.document.fileName
                self.tabs[index].document = self.viewModel.document
                self.tabs[index].isModified = false
            }
        }

        let observer5 = NotificationCenter.default.addObserver(forName: .openRecentFile, object: nil, queue: .main) { notification in
            if let url = notification.object as? URL {
                self.viewModel.loadDocument(from: url)
                let tabItem = TabItem(title: self.viewModel.document.fileName, document: self.viewModel.document, isModified: false)
                self.tabs.append(tabItem)
                self.selectedTab = tabItem
                // Force sync to ensure SimpleTextEditor updates
                self.viewModel.document = tabItem.document
            }
        }

        let observer6 = NotificationCenter.default.addObserver(forName: .newTab, object: nil, queue: .main) { _ in
            let newDoc = TextDocument(content: "")
            let tabItem = TabItem(title: newDoc.fileName, document: newDoc, isModified: false)
            self.tabs.append(tabItem)
            self.selectedTab = tabItem
            self.viewModel.document = newDoc
            self.viewModel.editorState = EditorState()
        }

        let observer7 = NotificationCenter.default.addObserver(forName: .closeTab, object: nil, queue: .main) { _ in
            self.closeCurrentTab()
        }

        let observer8 = NotificationCenter.default.addObserver(forName: .nextTab, object: nil, queue: .main) { _ in
            self.selectNextTab()
        }

        let observer9 = NotificationCenter.default.addObserver(forName: .previousTab, object: nil, queue: .main) { _ in
            self.selectPreviousTab()
        }

        notificationObservers = [observer1, observerOpenFile, observer2, observer3, observer4, observer5, observer6, observer7, observer8, observer9]
    }

    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers = []
    }
}
