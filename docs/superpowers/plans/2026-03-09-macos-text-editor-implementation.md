# MyText Premium Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all P0 features identified in the gap analysis to bring MyText to premium status

**Architecture:** Features organized by subsystem - each task builds incrementally with tests. Uses SwiftUI + NSTextView hybrid architecture with MVVM pattern.

**Tech Stack:** SwiftUI, AppKit (NSTextView), UserDefaults, NSRegularExpression

---

## File Structure

```
MyText/
├── Sources/
│   ├── App/
│   │   └── MyTextApp.swift              # Add recent files menu
│   ├── Models/
│   │   └── TextDocument.swift           # Add line ending detection
│   ├── ViewModels/
│   │   └── EditorViewModel.swift        # Add line operations, find navigation
│   ├── Views/
│   │   ├── ContentView.swift           # Add tabs container
│   │   ├── EditorView.swift            # Add current line highlight, code folding
│   │   ├── FindBarView.swift           # Add replace all, find navigation
│   │   ├── TabBarView.swift            # NEW: Tab management
│   │   └── SidebarView.swift           # Add recent files
│   └── Services/
│       ├── ThemeManager.swift           # Add system sync, custom themes
│       └── SyntaxHighlighter.swift      # Add incremental highlighting
```

---

## Chunk 1: Core Editing Enhancements

### Task 1: Recent Files

**Files:**
- Modify: `Sources/App/MyTextApp.swift`
- Modify: `Sources/Services/ThemeManager.swift`
- Test: Manual - Open files, check menu

- [ ] **Step 1: Add recent files storage to ThemeManager**

Add to `ThemeManager.swift`:
```swift
private let recentFilesKey = "recentFiles"
private let maxRecentFiles = 10

func recentFiles() -> [URL] {
    guard let paths = UserDefaults.standard.stringArray(forKey: recentFilesKey) else {
        return []
    }
    return paths.compactMap { URL(fileURLWithPath: $0) }
}

func addRecentFile(_ url: URL) {
    var files = recentFiles()
    files.removeAll { $0 == url }
    files.insert(url, at: 0)
    if files.count > maxRecentFiles {
        files = Array(files.prefix(maxRecentFiles))
    }
    UserDefaults.standard.set(files.map { $0.path }, forKey: recentFilesKey)
}
```

- [ ] **Step 2: Add Recent Files menu in MyTextApp**

Add to menu:
```swift
Menu("Recent Files") {
    ForEach(viewModel.themeManager.recentFiles(), id: \.self) { url in
        Button(url.lastPathComponent) {
            viewModel.loadDocument(from: url)
        }
    }
}
```

- [ ] **Step 3: Call addRecentFile when opening**

In `EditorViewModel.loadDocument(from:)`:
```swift
themeManager.addRecentFile(url)
```

- [ ] **Step 4: Commit**

```bash
git add Sources/App/MyTextApp.swift Sources/Services/ThemeManager.swift
git commit -m "feat: Add recent files support (up to 10)"
```

### Task 2: Line Operations

**Files:**
- Modify: `Sources/ViewModels/EditorViewModel.swift`
- Modify: `Sources/Views/EditorView.swift`
- Test: Select line, press Cmd+D, Cmd+Shift+Up/Down

- [ ] **Step 1: Add line operation methods to EditorViewModel**

Add to `EditorViewModel.swift`:
```swift
func duplicateLine(in text: String, cursorPos: Int) -> String {
    let lines = text.components(separatedBy: "\n")
    var currentPos = 0
    var lineIndex = 0

    for (index, line) in lines.enumerated() {
        if currentPos + line.count >= cursorPos {
            lineIndex = index
            break
        }
        currentPos += line.count + 1
    }

    guard lineIndex < lines.count else { return text }
    let line = lines[lineIndex]
    lines.insert(line, at: lineIndex)
    return lines.joined(separator: "\n")
}

func moveLineUp(in text: String, cursorPos: Int) -> String {
    let lines = text.components(separatedBy: "\n")
    var currentPos = 0
    var lineIndex = 0

    for (index, line) in lines.enumerated() {
        if currentPos + line.count >= cursorPos {
            lineIndex = index
            break
        }
        currentPos += line.count + 1
    }

    guard lineIndex > 0 else { return text }
    lines.swapAt(lineIndex, lineIndex - 1)
    return lines.joined(separator: "\n")
}

func moveLineDown(in text: String, cursorPos: Int) -> String {
    let lines = text.components(separatedBy: "\n")
    var currentPos = 0
    var lineIndex = 0

    for (index, line) in lines.enumerated() {
        if currentPos + line.count >= cursorPos {
            lineIndex = index
            break
        }
        currentPos += line.count + 1
    }

    guard lineIndex < lines.count - 1 else { return text }
    lines.swapAt(lineIndex, lineIndex + 1)
    return lines.joined(separator: "\n")
}
```

- [ ] **Step 2: Add keyboard shortcuts for line operations**

In `MyTextApp.swift`, add keyboard shortcuts:
```swift
.keyboardShortcut("d", modifiers: .command)          // Duplicate line
.keyboardShortcut(.upArrow, modifiers: [.command, .shift])  // Move line up
.keyboardShortcut(.downArrow, modifiers: [.command, .shift]) // Move line down
```

- [ ] **Step 3: Commit**

```bash
git add Sources/ViewModels/EditorViewModel.swift Sources/App/MyTextApp.swift
git commit -m "feat: Add line operations (duplicate, move up/down)"
```

### Task 3: Auto-Indent

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Test: Press Enter after `def foo():`, verify indentation

- [ ] **Step 1: Implement auto-indent in Coordinator**

Add to `EditorView.swift` Coordinator class:
```swift
func textView(_ textView: NSTextView, shouldInsertText string: String, replacingRangeCharRange charRange: NSRange) -> Bool {
    if string == "\n" {
        // Get current line indentation
        let currentLine = getCurrentLine(textView: textView)
        let indent = getIndentation(of: currentLine)

        // Check if we should add extra indent (after : or { or =)
        var extraIndent = ""
        let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix(":") || trimmed.hasSuffix("{") || trimmed.hasSuffix("=") {
            extraIndent = String(repeating: " ", count: viewModel.tabWidth)
        }

        let insertion = "\n" + indent + extraIndent
        textView.insertText(insertion, replacementRange: charRange)
        return false
    }
    return true
}

private func getCurrentLine(textView: NSTextView) -> String {
    let range = textView.currentLine()
    return (textView.string as NSString).substring(with: range)
}

private func getIndentation(of line: String) -> String {
    var indent = ""
    for char in line {
        if char == " " || char == "\t" {
            indent.append(char)
        } else {
            break
        }
    }
    return indent
}
```

- [ ] **Step 2: Add tab width property**

In `EditorViewModel.swift`, add:
```swift
var tabWidth: Int {
    UserDefaults.standard.integer(forKey: "tabWidth").nonZero ?? 4
}
```

- [ ] **Step 3: Commit**

```bash
git add Sources/Views/EditorView.swift Sources/ViewModels/EditorViewModel.swift
git commit -m "feat: Add auto-indent support"
```

---

## Chunk 2: Find & Replace

### Task 4: Replace All & Find Navigation

**Files:**
- Modify: `Sources/Views/FindBarView.swift`
- Modify: `Sources/ViewModels/EditorViewModel.swift`
- Test: Cmd+H for replace, Cmd+Shift+A for replace all

- [ ] **Step 1: Add replace all to FindBarView**

In `FindBarView.swift`, add:
```swift
@State private var replaceText: String = ""
@State private var replaceAllClicked = false

var body: some View {
    HStack {
        // Find field
        TextField("Find", text: $searchText)
            .textFieldStyle(.roundedBorder)

        // Replace field - NEW
        TextField("Replace", text: $replaceText)
            .textFieldStyle(.roundedBorder)

        // Replace buttons
        Button("Replace") {
            viewModel.replaceNext(searchText: searchText, replaceWith: replaceText)
        }

        Button("Replace All") {  // NEW
            viewModel.replaceAll(searchText: searchText, replaceWith: replaceText)
        }
        .keyboardShortcut("A", modifiers: [.command, .shift])

        // Navigation
        Button("Previous") {
            viewModel.findPrevious(searchText: searchText, isRegex: isRegex)
        }
        .keyboardShortcut("G", modifiers: [.command, .shift])

        Button("Next") {
            viewModel.findNext(searchText: searchText, isRegex: isRegex)
        }
        .keyboardShortcut("g", modifiers: .command)

        // Toggle buttons
        Toggle("Regex", isOn: $isRegex)
        Toggle("Case", isOn: $isCaseSensitive)

        Button("Close") {
            viewModel.showFindBar = false
        }
    }
    .padding(8)
}
```

- [ ] **Step 2: Add replace methods to EditorViewModel**

Add to `EditorViewModel.swift`:
```swift
func replaceNext(searchText: String, replaceWith: String) {
    // Get current text from document
    var content = document.content

    // Find and replace current selection or next match
    guard let range = findRange(in: content, searchText: searchText, startAt: editorState.cursorPosition) else { return }

    content.replaceSubrange(range, with: replaceWith)
    document.content = content
    document.isModified = true
}

func replaceAll(searchText: String, replaceWith: String) {
    var content = document.content

    let options: NSRegularExpression.Options = isCaseSensitive ? [] : .caseInsensitive
    guard let regex = try? NSRegularExpression(pattern: searchText, options: options) else { return }

    let range = NSRange(content.startIndex..., in: content)
    let matches = regex.matches(in: content, range: range)

    // Replace in reverse order to maintain ranges
    for match in matches.reversed() {
        if let swiftRange = Range(match.range, in: content) {
            content.replaceSubrange(swiftRange, with: replaceWith)
        }
    }

    document.content = content
    document.isModified = true
}

func findNext(searchText: String, isRegex: Bool) {
    guard let range = findRange(in: document.content, searchText: searchText, startAt: editorState.cursorPosition + 1) else { return }
    editorState.cursorPosition = range.lowerBound
    editorState.selectionStart = range.lowerBound
    editorState.selectionEnd = range.upperBound
}

func findPrevious(searchText: String, isRegex: Bool) {
    guard let range = findRangeBackward(in: document.content, searchText: searchText, startAt: editorState.cursorPosition - 1) else { return }
    editorState.cursorPosition = range.lowerBound
    editorState.selectionStart = range.lowerBound
    editorState.selectionEnd = range.upperBound
}

private func findRange(in content: String, searchText: String, startAt: Int) -> Range<String.Index>? {
    // Implementation using NSRegularExpression or simple string search
}

private func findRangeBackward(in content: String, searchText: String, startAt: Int) -> Range<String.Index>? {
    // Implementation for reverse search
}
```

- [ ] **Step 3: Commit**

```bash
git add Sources/Views/FindBarView.swift Sources/ViewModels/EditorViewModel.swift
git commit -m "feat: Add replace all and find navigation"
```

### Task 5: Highlight Matches

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Test: Search for text, verify all matches are highlighted

- [ ] **Step 1: Add match highlighting in Coordinator**

In `EditorView.swift` Coordinator class:
```swift
private var highlightedRanges: [NSRange] = []

func highlightMatches(for searchText: String, in textView: NSTextView) {
    guard !searchText.isEmpty else {
        clearHighlights(in: textView)
        return
    }

    let content = textView.string
    var ranges: [NSRange] = []

    // Simple search (extend for regex)
    var searchStart = content.startIndex
    while let range = content.range(of: searchText, range: searchStart..<content.endIndex) {
        let nsRange = NSRange(range, in: content)
        ranges.append(nsRange)
        searchStart = range.upperBound
    }

    highlightedRanges = ranges

    // Apply yellow highlight
    let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)
    for range in ranges {
        textView.textStorage?.addAttribute(.backgroundColor, value: highlightColor, range: range)
    }
}

func clearHighlights(in textView: NSTextView) {
    for range in highlightedRanges {
        textView.textStorage?.removeAttribute(.backgroundColor, range: range)
    }
    highlightedRanges = []
}
```

- [ ] **Step 2: Connect to FindBar**

In `FindBarView`, call highlight when search text changes:
```swift
.onChange(of: searchText) { _, newValue in
    viewModel.highlightMatches(newValue)
}
```

- [ ] **Step 3: Commit**

```bash
git add Sources/Views/EditorView.swift Sources/Views/FindBarView.swift
git commit -m "feat: Add match highlighting in editor"
```

---

## Chunk 3: View Enhancements

### Task 6: Current Line Highlight

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Test: Move cursor, verify current line has subtle highlight

- [ ] **Step 1: Add current line tracking in Coordinator**

In `EditorView.swift` Coordinator class:
```swift
private var currentLineHighlight: NSRange?

func textViewDidChangeSelection(_ notification: Notification) {
    guard let textView = notification.object as? NSTextView else { return }
    highlightCurrentLine(in: textView)
}

private func highlightCurrentLine(in textView: NSTextView) {
    // Remove old highlight
    if let oldRange = currentLineHighlight {
        textView.textStorage?.removeAttribute(.backgroundColor, range: oldRange)
    }

    // Get current line range
    let lineRange = textView.currentLine()
    guard lineRange.length > 0 else { return }

    // Add new highlight
    let highlightColor = NSColor(Color(themeManager.currentTheme.currentLineBackground))
    textView.textStorage?.addAttribute(.backgroundColor, value: highlightColor, range: lineRange)
    currentLineHighlight = lineRange
}
```

- [ ] **Step 2: Add currentLineBackground to themes**

In `ThemeManager.swift`, add to EditorTheme:
```swift
var currentLineBackground: String { get }  // e.g., "#2D2D2D"
```

- [ ] **Step 3: Commit**

```bash
git add Sources/Views/EditorView.swift Sources/Services/ThemeManager.swift
git commit -m "feat: Add current line highlight"
```

### Task 7: Word Wrap

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Test: Toggle word wrap, verify long lines wrap

- [ ] **Step 1: Add word wrap toggle to EditorViewModel**

Add to `EditorViewModel.swift`:
```swift
@Published var wordWrap: Bool = false

func toggleWordWrap() {
    wordWrap.toggle()
    UserDefaults.standard.set(wordWrap, forKey: "wordWrap")
}
```

- [ ] **Step 2: Apply word wrap in SimpleTextEditor**

In `EditorView.swift`, modify `makeNSView`:
```swift
textView.textContainer?.widthTracksTextView = !viewModel.wordWrap
if !viewModel.wordWrap {
    textView.textContainer?.containerSize = NSSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
    )
}
```

- [ ] **Step 3: Add toggle in StatusBar or Settings**

- [ ] **Step 4: Commit**

```bash
git add Sources/Views/EditorView.swift Sources/ViewModels/EditorViewModel.swift
git commit -m "feat: Add word wrap support"
```

---

## Chunk 4: Theme Enhancements

### Task 8: Custom Themes & System Sync

**Files:**
- Modify: `Sources/Services/ThemeManager.swift`
- Test: Create custom theme, toggle system sync

- [ ] **Step 1: Add custom theme support**

In `ThemeManager.swift`:
```swift
func saveCustomTheme(_ theme: EditorTheme, name: String) {
    // Save to UserDefaults as JSON
}

func loadCustomThemes() -> [EditorTheme] {
    // Load from UserDefaults
}

func importTheme(from url: URL) throws {
    // Parse JSON theme file
}
```

- [ ] **Step 2: Add system appearance sync**

In `ThemeManager.swift`:
```swift
@Published var syncWithSystem: Bool = false

func updateForSystemAppearance() {
    guard syncWithSystem else { return }
    let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    currentTheme = isDark ? darkTheme : lightTheme
}
```

- [ ] **Step 3: Add observers for appearance change**

In `ThemeManager.init`:
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(appearanceChanged),
    name: NSApplication.didChangeOcclusionStateNotification,
    object: nil
)
```

- [ ] **Step 4: Commit**

```bash
git add Sources/Services/ThemeManager.swift
git commit -m "feat: Add custom themes and system sync"
```

---

## Chunk 5: Tab Management

### Task 9: Multiple Tabs

**Files:**
- Create: `Sources/Views/TabBarView.swift`
- Modify: `Sources/Views/ContentView.swift`
- Modify: `Sources/App/MyTextApp.swift`
- Test: Cmd+T for new tab, Cmd+W to close, click to switch

- [ ] **Step 1: Create TabBarView**

Create `Sources/Views/TabBarView.swift`:
```swift
struct TabBarView: View {
    @Binding var tabs: [TabItem]
    @Binding var selectedTab: TabItem?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabItemView(tab: tab, isSelected: tab.id == selectedTab?.id)
                    .onTapGesture {
                        selectedTab = tab
                    }
            }

            Button("+") {
                // New tab
            }
            .buttonStyle(.plain)
        }
        .frame(height: 32)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TabItem: Identifiable {
    let id = UUID()
    var title: String
    var document: TextDocument
    var isModified: Bool
}

struct TabItemView: View {
    let tab: TabItem
    let isSelected: Bool

    var body: some View {
        HStack {
            if tab.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
            Text(tab.title)
                .lineLimit(1)

            Button("x") {
                // Close tab
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .background(isSelected ? Color(NSColor.controlBackgroundColor) : Color.clear)
    }
}
```

- [ ] **Step 2: Update ContentView for tab container**

In `ContentView.swift`:
```swift
struct ContentView: View {
    @StateObject var viewModel: EditorViewModel
    @State private var tabs: [TabItem] = []
    @State private var selectedTab: TabItem?

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 {
                TabBarView(tabs: $tabs, selectedTab: $selectedTab)
            }

            // Existing editor view
            if let selectedTab = selectedTab {
                EditorView(viewModel: createViewModel(for: selectedTab), themeManager: themeManager)
            }
        }
    }
}
```

- [ ] **Step 3: Add keyboard shortcuts**

In `MyTextApp.swift`:
```swift
.keyboardShortcut("t", modifiers: .command)  // New tab
.keyboardShortcut("w", modifiers: .command)  // Close tab
.keyboardShortcut(.tab, modifiers: .command) // Next tab
.keyboardShortcut(.tab, modifiers: [.command, .shift]) // Previous tab
```

- [ ] **Step 4: Commit**

```bash
git add Sources/Views/TabBarView.swift Sources/Views/ContentView.swift Sources/App/MyTextApp.swift
git commit -m "feat: Add tab management"
```

---

## Chunk 6: Code Folding

### Task 10: Code Folding

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Modify: `Sources/Services/SyntaxHighlighter.swift`
- Test: Click fold indicators, verify regions collapse

- [ ] **Step 1: Add fold state tracking**

In `EditorViewModel.swift`:
```swift
struct FoldRegion: Identifiable {
    let id = UUID()
    let startLine: Int
    let endLine: Int
    var isFolded: Bool
}

@Published var foldRegions: [FoldRegion] = []
```

- [ ] **Step 2: Add fold indicators to gutter**

In `EditorView.swift`, add fold indicator column:
```swift
struct LineNumbersView: View {
    // Add fold indicator column (e.g., 16pt width)
    // Render ▼ or ▶ based on fold state
}
```

- [ ] **Step 3: Implement fold logic**

In `EditorViewModel.swift`:
```swift
func toggleFold(at line: Int) {
    if let index = foldRegions.firstIndex(where: { $0.startLine == line }) {
        foldRegions[index].isFolded.toggle()
    }
}

func foldAll() {
    for index in foldRegions.indices {
        foldRegions[index].isFolded = true
    }
}

func unfoldAll() {
    for index in foldRegions.indices {
        foldRegions[index].isFolded = false
    }
}
```

- [ ] **Step 4: Detect foldable regions**

In `SyntaxHighlighter.swift`, add function:
```swift
func detectFoldRegions(in content: String, language: ProgrammingLanguage) -> [FoldRegion] {
    // Parse for functions, classes, comments
    // Return regions with start/end lines
}
```

- [ ] **Step 5: Commit**

```bash
git add Sources/Views/EditorView.swift Sources/Services/SyntaxHighlighter.swift Sources/ViewModels/EditorViewModel.swift
git commit -m "feat: Add code folding support"
```

---

## Summary

| Task | Feature | Complexity |
|------|---------|------------|
| 1 | Recent Files | Low |
| 2 | Line Operations | Medium |
| 3 | Auto-Indent | Medium |
| 4 | Replace All & Find Nav | Medium |
| 5 | Highlight Matches | Low |
| 6 | Current Line Highlight | Low |
| 7 | Word Wrap | Low |
| 8 | Custom Themes & System Sync | Medium |
| 9 | Multiple Tabs | High |
| 10 | Code Folding | High |

Total: 10 tasks, approximately 20-30 steps with commits.

---

*Plan Version: 1.0*
*Created: 2026-03-09*
*For: MyText Premium Specification*
