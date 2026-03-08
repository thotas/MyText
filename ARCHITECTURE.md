# MyText Architecture

## Overview

MyText is a native macOS text editor built with SwiftUI and AppKit, designed for editing plain text files with syntax highlighting support.

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      MyTextApp                              │
│                    (SwiftUI App)                           │
└─────────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  ContentView    │ │  AppDelegate │ │   Settings      │
│  (Main Window) │ │              │ │   (Preferences) │
└────────┬────────┘ └──────────────┘ └──────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   EditorViewModel                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - document: TextDocument                           │   │
│  │  - editorState: EditorState                        │   │
│  │  - detectedLanguage: ProgrammingLanguage           │   │
│  │  - syntaxHighlighter: SyntaxHighlighter            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              Views (SwiftUI Components)                     │
│  ┌──────────┐ ┌───────────┐ ┌────────────┐ ┌─────────┐ │
│  │ Toolbar  │ │  Sidebar  │ │   Editor   │ │ Status  │ │
│  │  View    │ │   View    │ │   View     │ │  Bar   │ │
│  └──────────┘ └───────────┘ └─────┬──────┘ └─────────┘ │
│                                    │                       │
│                           ┌────────▼────────┐               │
│                           │ TextEditorView │               │
│                           │ (NSTextView)   │               │
│                           └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. App Layer (`MyTextApp.swift`)
- SwiftUI App entry point
- WindowGroup configuration
- Menu bar commands (New, Open, Save)
- Settings scene

### 2. Models
- **TextDocument**: Represents a text file with content, URL, encoding
- **EditorState**: Cursor position, line/column, selection
- **EditorTheme**: Colors for syntax highlighting and UI

### 3. ViewModels
- **EditorViewModel**: Main state management
  - Document operations (new, open, save)
  - Content updates
  - Cursor position tracking
  - Language detection

### 4. Views
- **ContentView**: Main container with toolbar, editor, status bar
- **EditorView**: Text editor with line numbers
- **TextEditorView**: NSViewRepresentable wrapping NSTextView
- **ToolbarView**: Native toolbar with actions
- **SidebarView**: File info and language selection
- **StatusBarView**: Line/column, encoding, modification status
- **FindBarView**: Search functionality
- **SettingsView**: Theme and preferences

### 5. Services
- **ThemeManager**: Theme persistence (UserDefaults)
- **SyntaxHighlighter**: Regex-based syntax highlighting

## Data Flow

### Opening a File
1. User triggers Open (Cmd+O or toolbar)
2. `EditorViewModel.openDocument()` shows NSOpenPanel
3. File URL selected → `loadDocument(from:)`
4. Content loaded as String
5. `TextDocument` created with content
6. `detectLanguage()` determines syntax highlighting
7. `SyntaxHighlighter.highlight()` applies colors
8. UI updates via @Published properties

### Editing Text
1. User types in NSTextView
2. NSTextViewDelegate.textDidChange fires
3. Coordinator calls `viewModel.updateContent()`
4. Document marked as modified
5. Syntax highlighting reapplied
6. Status bar updates (line/column, modified indicator)

### Saving a File
1. User triggers Save (Cmd+S)
2. If no URL → Save As shows NSSavePanel
3. Content written to file URL
4. Document marked as saved (not modified)

## State Management

- **SwiftUI @Published**: Reactive UI updates
- **@ObservableObject**: ViewModel as single source of truth
- **UserDefaults**: Persistent preferences

### UserDefaults Keys
| Key | Type | Default |
|-----|------|---------|
| selectedTheme | String | "Dark" |
| fontSize | Double | 14.0 |
| fontName | String | "SF Mono" |
| tabWidth | Int | 4 |
| showLineNumbers | Bool | true |

## Storage Schema

### TextDocument (in-memory)
```
TextDocument {
  id: UUID
  content: String
  fileURL: URL?
  isModified: Bool
  encoding: String.Encoding (.utf8)
  lineEnding: LineEnding (.unix)
}
```

### EditorState (in-memory)
```
EditorState {
  cursorPosition: Int
  selectionStart: Int?
  selectionEnd: Int?
  scrollOffset: CGPoint
  lineNumber: Int
  columnNumber: Int
}
```

## Concurrency Model

- **@MainActor**: All UI operations on main thread
- **SwiftUI Dispatch**: Automatic main thread dispatch for @Published
- **NSTextViewDelegate**: Calls dispatched to main thread

## Syntax Highlighting Engine

### Architecture
- Custom regex-based engine
- TextMate-compatible pattern format
- NSAttributedString for styled text

### Supported Languages
1. **Shell Script**: Keywords, variables, strings, comments
2. **SQL**: SQL keywords, functions, strings, comments
3. **Python**: Keywords, decorators, functions, classes, strings, comments

### Pattern Matching
- Language definition contains array of patterns
- Each pattern has:
  - Name identifier
  - Regex pattern
  - Scope (keyword, string, comment, etc.)
  - Optional capture group for extraction

## Error Handling

- **File I/O**: Try-catch with error printing
- **Regex**: Guard with optional regex creation
- **Theme**: Fallback to default dark theme

## Extension Points

1. **New Languages**: Add to LanguageDefinitions in SyntaxHighlighter
2. **New Themes**: Add EditorTheme static instance in ThemeManager
3. **New Features**: Add to EditorViewModel, bind in Views

## Build Configuration

- **Platform**: macOS 14.0+
- **Swift**: 5.9
- **Architecture**: arm64
- **Code Signing**: Automatic (Development)
- **Hardened Runtime**: Enabled (non-sandboxed)
