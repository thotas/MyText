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
- **Line Numbers** - Toggle line numbers in the sidebar
- **Find & Replace** - Search with case sensitivity and regex support
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
│            │  6  if __name__ == "__main__":                 │
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

## How to Use

### Opening Files
- **Cmd+O** - Open file dialog
- Drag and drop files onto the app window
- Double-click text files in Finder (with MyText as default app)

### Editing
- **Cmd+N** - New document
- **Cmd+S** - Save
- **Cmd+Shift+S** - Save As
- **Cmd+F** - Find
- **Cmd+A** - Select All
- **Cmd+Z** - Undo
- **Cmd+Shift+Z** - Redo

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
│   │   ├── FindBarView.swift       # Find/replace
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
| Cmd+O | Open |
| Cmd+S | Save |
| Cmd+Shift+S | Save As |
| Cmd+F | Find |
| Cmd+, | Settings |
| Cmd+Q | Quit |

## Limitations

- Plain text only (no rich text formatting)
- No multiple cursors
- No code folding
- No plugin support (v1.0)

## Roadmap

- [ ] Additional language support (JavaScript, TypeScript, Go, Rust)
- [ ] Code folding
- [ ] Multiple cursors
- [ ] Mini-map preview
- [ ] Vim mode
- [ ] Git integration

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
