# MyText - Architectural Decisions

**Project:** MyText
**Type:** Native macOS Text Editor
**Date:** 2026-03-08
**Version:** 1.0.0

---

## 1. Platform & Stack

### Decision: Hybrid SwiftUI + AppKit Approach

**Chosen Option:** SwiftUI for the application shell, windows, and UI components, combined with AppKit's NSTextView wrapped in NSViewRepresentable for the core text editing functionality.

**Rationale:**
- SwiftUI is Apple's recommended modern framework for macOS development and provides:
  - Declarative UI syntax that produces beautiful, consistent interfaces
  - Native dark mode support with minimal configuration
  - Seamless integration with macOS system appearance
  - Modern state management via @State, @Binding, and @Observable

- NSTextView (AppKit) remains the gold standard for text editing on macOS because:
  - It's the underlying engine used by TextMate, Xcode, and most professional macOS editors
  - Provides sophisticated text layout, line spacing, and font rendering
  - Supports advanced features like undo management, find/replace, and text attachments
  - Offers proven performance with large files (100K+ lines)

- The hybrid approach delivers the best of both worlds: modern UI development with proven text editing capability.

**Alternatives Considered:**
- **Pure SwiftUI (TextEditor):** Rejected because SwiftUI's TextEditor lacks:
  - Custom undo management granularity
  - Fine-grained text view customization
  - Proven performance with very large files
  - Full control over text rendering pipeline

- **Pure AppKit:** Rejected because:
  - More verbose UI code
  - Manual dark mode handling
  - Steeper learning curve for modern SwiftUI patterns

---

## 2. Architecture Pattern

### Decision: MVVM with Document-Based Architecture

**Chosen Option:** Combine SwiftUI's MVVM pattern with macOS's built-in document-based architecture.

**Implementation Structure:**
```
MyText/
├── App/
│   └── MyTextApp.swift          # SwiftUI App entry point
├── Documents/
│   └── TextDocument.swift       # Document model (file handling)
├── ViewModels/
│   ├── EditorViewModel.swift    # Editor state & logic
│   └── ThemeViewModel.swift     # Theme management
├── Views/
│   ├── MainWindow.swift         # Main window controller
│   ├── EditorView.swift         # Primary editor UI
│   ├── TextViewWrapper.swift    # NSTextView wrapper
│   └── Components/              # Reusable UI components
├── Models/
│   ├── TextDocument.swift       # Document data model
│   └── EditorState.swift        # Editor state model
├── Services/
│   ├── SyntaxHighlighter.swift  # Syntax highlighting engine
│   ├── LanguageDefinitions/      # Language grammar files
│   └── ThemeManager.swift       # Theme loading/applying
└── Resources/
    ├── Assets.xcassets          # App icons, colors
    └── Themes/                  # Theme definition files
```

---

## 3. Syntax Highlighting Approach

### Decision: Custom Engine with TextMate-Compatible Language Definitions

**Chosen Option:** Build a custom syntax highlighting engine that uses JSON-based language grammar files (compatible with TextMate/VS Code grammar format).

**Supported Languages (Phase 1):**
- Shell Script (bash, sh, zsh)
- SQL (PostgreSQL, MySQL, SQLite)
- Python (3.x)

---

## 4. Data & Persistence

### Decision: UserDefaults for Preferences, Native Document System for Files

**Preferences Storage (UserDefaults):**
| Key | Type | Description |
|-----|------|-------------|
| `windowFrame` | Data | Main window position/size |
| `recentFiles` | [String] | Array of recent file paths |
| `theme` | String | Selected theme name |
| `fontSize` | Double | Editor font size |
| `fontName` | String | Editor font family |
| `showSidebar` | Bool | Sidebar visibility |
| `lineNumbers` | Bool | Line number display |
| `tabWidth` | Int | Spaces per tab |

---

## 5. UI/UX Structure

### Decision: Single-Window Document Model with Toolbar and Collapsible Sidebar

**Window Layout:**
- Top toolbar (native)
- Left sidebar (collapsible)
- Center editor area
- Bottom status bar

**Dark Mode Colors:**
| Element | Hex |
|---------|-----|
| Background | #1E1E1E |
| Editor Background | #252526 |
| Primary Text | #D4D4D4 |
| Keyword (Blue) | #569CD6 |
| String (Orange) | #CE9178 |
| Comment (Green) | #6A9955 |

---

## 6. Additional Decisions

- ** DesignFont:** SF Mono (system monospace font) as default
- **Line Numbers:** Enabled by default, toggleable
- **Tab Width:** 4 spaces per tab (configurable)
- **Search:** Native find bar (Cmd+F)

---

## 7. Summary

| Decision Area | Choice |
|---------------|--------|
| UI Framework | SwiftUI + NSTextView |
| Architecture | MVVM + Document |
| Syntax Highlighting | Custom + TextMate grammar |
| Persistence | UserDefaults + Native docs |
| Theme | Dark by default |
| Font | SF Mono |
