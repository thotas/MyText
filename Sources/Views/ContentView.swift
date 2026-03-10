import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = EditorViewModel()
    @State private var showFindBar = false
    @State private var showQuickOpen = false
    @State private var showGoToLine = false
    @State private var showSidebar = true
    @State private var tabs: [TabItem] = []
    @State private var selectedTab: TabItem?
    @State private var splitMode: SplitMode = .none

    // Store notification observers to remove them later
    @State private var notificationObservers: [NSObjectProtocol] = []

    enum SplitMode {
        case none
        case horizontal  // Top/bottom
        case vertical    // Left/right
    }

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

                // Editor (with optional split)
                editorContent

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
        .sheet(isPresented: $showQuickOpen) {
            QuickOpenView(isPresented: $showQuickOpen, themeManager: themeManager)
        }
        .sheet(isPresented: $showGoToLine) {
            GoToLineView(isPresented: $showGoToLine, viewModel: viewModel, themeManager: themeManager)
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "p" {
                    showQuickOpen = true
                    return nil
                }
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "l" {
                    showGoToLine = true
                    return nil
                }
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "g" {
                    if event.modifierFlags.contains(.shift) {
                        // Cmd+Shift+G: Find Previous
                        NotificationCenter.default.post(name: .findPrevious, object: nil)
                    } else {
                        // Cmd+G: Find Next
                        NotificationCenter.default.post(name: .findNext, object: nil)
                    }
                    return nil
                }
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "h" {
                    // Cmd+H: Replace (show find bar)
                    showFindBar = true
                    return nil
                }
                return event
            }
        }
    }

    @ViewBuilder
    private var editorContent: some View {
        switch splitMode {
        case .none:
            SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .horizontal:
            VSplitView {
                SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .vertical:
            HSplitView {
                SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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

        // Handle Quick Open (Cmd+P)
        let observerQuickOpen = NotificationCenter.default.addObserver(forName: .quickOpen, object: nil, queue: .main) { _ in
            self.showQuickOpen = true
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

        let observer10 = NotificationCenter.default.addObserver(forName: .goToLine, object: nil, queue: .main) { _ in
            self.showGoToLine = true
        }

        let observer11 = NotificationCenter.default.addObserver(forName: .findNext, object: nil, queue: .main) { _ in
            if !self.showFindBar {
                self.showFindBar = true
            }
            // findNext will be triggered by the FindBarView's onSubmit
        }

        let observer12 = NotificationCenter.default.addObserver(forName: .findPrevious, object: nil, queue: .main) { _ in
            if !self.showFindBar {
                self.showFindBar = true
            }
            // findPrevious will be triggered by FindBarView
        }

        let observer13 = NotificationCenter.default.addObserver(forName: .duplicateLine, object: nil, queue: .main) { _ in
            self.viewModel.duplicateLine()
        }

        let observer14 = NotificationCenter.default.addObserver(forName: .moveLineUp, object: nil, queue: .main) { _ in
            self.viewModel.moveLineUp()
        }

        let observer15 = NotificationCenter.default.addObserver(forName: .moveLineDown, object: nil, queue: .main) { _ in
            self.viewModel.moveLineDown()
        }

        let observer16 = NotificationCenter.default.addObserver(forName: .toggleComment, object: nil, queue: .main) { _ in
            self.viewModel.toggleComment()
        }

        let observer17 = NotificationCenter.default.addObserver(forName: .toggleFold, object: nil, queue: .main) { _ in
            self.viewModel.toggleFoldAtCursor()
        }

        let observer18 = NotificationCenter.default.addObserver(forName: .foldAll, object: nil, queue: .main) { _ in
            self.viewModel.foldAll()
        }

        let observer19 = NotificationCenter.default.addObserver(forName: .unfoldAll, object: nil, queue: .main) { _ in
            self.viewModel.unfoldAll()
        }

        let observer20 = NotificationCenter.default.addObserver(forName: .selectLine, object: nil, queue: .main) { _ in
            self.viewModel.selectLine()
        }

        let observerUppercase = NotificationCenter.default.addObserver(forName: .uppercaseSelection, object: nil, queue: .main) { _ in
            self.viewModel.uppercaseSelection()
        }

        let observerLowercase = NotificationCenter.default.addObserver(forName: .lowercaseSelection, object: nil, queue: .main) { _ in
            self.viewModel.lowercaseSelection()
        }

        let observerSortLines = NotificationCenter.default.addObserver(forName: .sortLines, object: nil, queue: .main) { _ in
            self.viewModel.sortLines()
        }

        // Toggle Invisibles observer
        let observerToggleInvisibles = NotificationCenter.default.addObserver(forName: .toggleInvisibles, object: nil, queue: .main) { _ in
            let currentValue = ThemeManager.shared.showInvisibles()
            ThemeManager.shared.setShowInvisibles(!currentValue)
            // Trigger view update by posting a notification that SimpleTextEditor responds to
            NotificationCenter.default.post(name: .refreshEditor, object: nil)
        }

        // Trim Trailing Whitespace observer
        let observerTrimTrailingWhitespace = NotificationCenter.default.addObserver(forName: .trimTrailingWhitespace, object: nil, queue: .main) { _ in
            self.viewModel.trimTrailingWhitespaceCommand()
        }

        // Split view observers
        let observerSplitH = NotificationCenter.default.addObserver(forName: .splitHorizontal, object: nil, queue: .main) { _ in
            self.splitMode = self.splitMode == .horizontal ? .none : .horizontal
        }

        let observerSplitV = NotificationCenter.default.addObserver(forName: .splitVertical, object: nil, queue: .main) { _ in
            self.splitMode = self.splitMode == .vertical ? .none : .vertical
        }

        let observerSplitClose = NotificationCenter.default.addObserver(forName: .splitClose, object: nil, queue: .main) { _ in
            self.splitMode = .none
        }

        notificationObservers = [observer1, observerOpenFile, observerQuickOpen, observer2, observer3, observer4, observer5, observer6, observer7, observer8, observer9, observer10, observer11, observer12, observer13, observer14, observer15, observer16, observer17, observer18, observer19, observer20, observerUppercase, observerLowercase, observerSortLines, observerToggleInvisibles, observerTrimTrailingWhitespace, observerSplitH, observerSplitV, observerSplitClose]
    }

    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers = []
    }
}
