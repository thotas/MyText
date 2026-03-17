# MyText

A beautiful native macOS plain text editor with syntax highlighting, inspired by TextMate.

## Features

- **Plain Text Only** - Focus on your content without formatting distractions
- **Syntax Highlighting** - Built-in support for:
  - Shell Script (bash, sh, zsh)
  - SQL
  - Python
- **Dark Mode by Default** - Beautiful dark themes to reduce eye strain
- **Multiple Themes** - Choose from Dark, Light, Midnight, Monokai, or Dracula
- **Custom Themes** - Import and export your own color schemes
- **Line Numbers** - Toggle line numbers in the sidebar
- **Find & Replace** - Search with case sensitivity support
- **Quick Open** - Quickly open recent files with Cmd+P
- **Go to Line** - Jump to any line number with Cmd+L
- **Code Folding** - Fold and unfold code blocks
- **Tab Management** - Multiple tabs for working on several files
- **Split View** - Split editor horizontally or vertically
- **Auto-Pair Brackets** - Automatically close brackets, quotes, and parentheses
- **Auto-Indent** - Smart indentation for new lines
- **Line Operations** - Duplicate, move up/down, toggle comments
- **Bracket Matching** - Highlight and jump to matching brackets
- **Word Wrap** - Toggle word wrapping
- **Line Length Guide** - Visual guide at configurable column
- **Auto-Save** - Automatically save your work
- **Trim Trailing Whitespace** - Clean up whitespace on save
- **macOS Native** - Uses SwiftUI + AppKit for the best native experience

## Screenshot

```
┌─────────────────────────────────────────────────────────────┐
│ [New] [Open] [Save]              MyText.py *                │
├────────────┬────────────────────────────────────────────────┤
│            │  1  #!/usr/bin/env python3                     │
│  Document  │  2                                              │
│            │  3  def hello():                                │
│  Language  │  4      print("Hello, World!")                 │
│  Python    │  5                                              │
│            │  6  if __name__ == "__main__":                  │
│  Lines 6   │  7      hello()                                │
│            │                                                │
├────────────┴────────────────────────────────────────────────┤
│ Ln 7, Col 7 | Python | UTF-8 | Unix (LF)    ● Modified    │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **AppKit (NSTextView)** - Professional text editing engine
- **MVVM Architecture** - Clean separation of concerns
- **Custom Syntax Highlighter** - Regex-based highlighting engine

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/thotas/MyText.git

# Open in Xcode
open MyText.xcodeproj

# Build and run (Cmd+R)
```

### Pre-built App

1. Download the latest release from GitHub
2. Double-click `MyText.app` to launch
3. Or drag to Applications folder

The built app is also available at: `~/Applications/myApps/MyText.app`

## How to Use

### Opening Files
- **Cmd+O** - Open file dialog
- **Cmd+P** - Quick Open (recent files)
- Drag and drop files onto the app window
- Double-click text files in Finder (with MyText as default app)

### Editing
- **Cmd+N** - New document
- **Cmd+T** - New tab
- **Cmd+W** - Close tab
- **Cmd+S** - Save
- **Cmd+Shift+S** - Save As
- **Cmd+F** - Find
- **Cmd+L** - Go to Line
- **Cmd+A** - Select All
- **Cmd+Z** - Undo
- **Cmd+Shift+Z** - Redo

### Line Operations
- **Cmd+Shift+D** - Duplicate current line
- **Cmd+Shift+Up** - Move line up
- **Cmd+Shift+Down** - Move line down
- **Cmd+/** - Toggle comment
- **Cmd+Shift+M** - Jump to matching bracket
- **Cmd+Option+L** - Select all occurrences

### Text Transformation
- **Cmd+Shift+U** - Uppercase selection
- **Cmd+Option+Shift+U** - Lowercase selection
- **Cmd+Shift+J** - Join lines

### View
- **Cmd+Shift+]** - Next tab
- **Cmd+Shift+[** - Previous tab
- **Cmd++** - Zoom in
- **Cmd+-** - Zoom out
- **Cmd+0** - Reset zoom

### Split View
- Split editor horizontally or vertically
- Close split view

### Customization
- **Cmd+,** (Cmd + comma) - Open Settings
- Theme selector in toolbar
- Toggle sidebar with toolbar button

## Project Structure

```
MyText/
├── Sources/
│   ├── App/
│   │   └── MyTextApp.swift          # App entry point
│   ├── Models/
│   │   └── TextDocument.swift       # Document model
│   ├── ViewModels/
│   │   └── EditorViewModel.swift    # Editor logic
│   ├── Views/
│   │   ├── ContentView.swift       # Main view
│   │   ├── EditorView.swift        # Text editor
│   │   ├── ToolbarView.swift       # Toolbar
│   │   ├── SidebarView.swift       # Sidebar
│   │   ├── StatusBarView.swift     # Status bar
│   │   ├── TabBarView.swift        # Tab management
│   │   ├── FindBarView.swift       # Find/replace
│   │   ├── QuickOpenView.swift     # Quick open
│   │   ├── GoToLineView.swift      # Go to line
│   │   └── SettingsView.swift      # Settings
│   └── Services/
│       ├── ThemeManager.swift       # Theme management
│       └── SyntaxHighlighter.swift  # Syntax highlighting
├── Resources/
│   ├── Info.plist
│   ├── Assets.xcassets/
│   └── MyText.entitlements
├── project.yml                     # XcodeGen config
├── README.md
├── DECISIONS.md
├── ARCHITECTURE.md
└── MyText.app                      # Built application
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+N | New Document |
| Cmd+T | New Tab |
| Cmd+W | Close Tab |
| Cmd+O | Open |
| Cmd+P | Quick Open |
| Cmd+S | Save |
| Cmd+Shift+S | Save As |
| Cmd+F | Find |
| Cmd+L | Go to Line |
| Cmd+, | Settings |
| Cmd+Q | Quit |
| Cmd+Shift+] | Next Tab |
| Cmd+Shift+[ | Previous Tab |
| Cmd+Shift+D | Duplicate Line |
| Cmd+Shift+Up | Move Line Up |
| Cmd+Shift+Down | Move Line Down |
| Cmd+/ | Toggle Comment |
| Cmd+Shift+M | Jump to Matching Bracket |
| Cmd+Option+L | Select All Occurrences |
| Cmd+Shift+U | Uppercase |
| Cmd+Option+Shift+U | Lowercase |
| Cmd+Shift+J | Join Lines |
| Cmd++ | Zoom In |
| Cmd+- | Zoom Out |
| Cmd+0 | Reset Zoom |

## Roadmap

- [ ] Additional language support (JavaScript, TypeScript, Go, Rust)
- [x] Code folding (implemented)
- [ ] Multiple cursors
- [ ] Mini-map preview
- [ ] Vim mode
- [ ] Git integration

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
