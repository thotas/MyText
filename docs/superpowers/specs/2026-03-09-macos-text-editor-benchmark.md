# MyText Premium — Technical Specification & Benchmark

**Project:** MyText (Premium macOS Text Editor)
**Date:** 2026-03-09
**Version:** 2.0.0
**Purpose:** Technical specification and gap analysis benchmark

---

## 1. Product Vision

### 1.1 Core Philosophy

A high-performance, minimalist plain-text editor inspired by TextMate, rebuilt as a premium macOS-native application.

**Key Pillars:**
- **Performance First:** Sub-100ms response times, optimized for large files (100K+ lines)
- **Native Excellence:** Deep macOS integration using SwiftUI + AppKit
- **Distraction-Free:** Clean interface that gets out of the way
- **Apple-First:** Respects macOS design language, keyboard conventions, and user expectations

### 1.2 Target Languages (Phase 1)

| Language | Extensions | Status |
|----------|------------|--------|
| Python | `.py`, `.pyw`, `.pyi` | Implemented |
| Shell Script | `.sh`, `.bash`, `.zsh`, `.fish` | Implemented |
| SQL | `.sql`, `.pgsql`, `.mysql` | Implemented |
| Plain Text | `.txt`, `.md`, `.log` | Implemented |

**Extensibility:** Language definitions use TextMate-compatible grammar format for future expansion (JavaScript, TypeScript, Go, Rust).

### 1.3 Target Users

- Developers who prefer lightweight, fast editors
- Writers needing distraction-free plain text
- System administrators working with configs and scripts
- Users migrating from TextMate, Sublime Text, or Vim

---

## 2. UI/UX Specifications

### 2.1 Window Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ [Toolbar: New | Open | Save | Theme | Settings]              │
├─────────────┬────────────────────────────────────────────────┤
│             │                                                │
│  Sidebar    │              Editor Area                       │
│  (220px)    │              (NSTextView)                     │
│             │                                                │
│  - File     │  ┌──┬─────────────────────────────────────┐   │
│    Info     │  │1 │ #!/usr/bin/env python3             │   │
│             │  │2 │                                      │   │
│  - Language │  │3 │ def hello():                        │   │
│    Selector │  │4 │     print("Hello, World!")          │   │
│             │  │5 │                                      │   │
│  - Stats    │  │6 │ if __name__ == "__main__":          │   │
│             │  │7 │     hello()                         │   │
│             │  └──┴─────────────────────────────────────┘   │
│             │                                                │
├─────────────┴────────────────────────────────────────────────┤
│ [Status Bar: Ln 7, Col 7 | Python | UTF-8 | LF | ● Modified] │
└──────────────────────────────────────────────────────────────┘
```

**Window Properties:**
- Minimum size: 600×400 points
- Default size: 1200×800 points
- Resizable with native window controls

### 2.2 Visual Design — Premium Native

#### Color Palette

**Dark Theme (Default):**
| Element | Hex Code | Usage |
|---------|----------|-------|
| Background | `#1E1E1E` | Window background |
| Editor Background | `#252526` | Text editor area |
| Sidebar Background | `#252526` (vibrancy) | Sidebar with `.sidebar` material |
| Primary Text | `#D4D4D4` | Main code text |
| Secondary Text | `#808080` | Comments, line numbers |
| Selection | `#264F78` | Text selection highlight |
| Cursor | `#AEAFAD` | Insertion point |
| Current Line | `#2D2D2D` | Active line highlight |

**Syntax Colors:**
| Scope | Hex Code | Example |
|-------|----------|---------|
| Keywords | `#569CD6` | `def`, `if`, `SELECT` |
| Strings | `#CE9178` | `"hello"`, `'world'` |
| Comments | `#6A9955` | `# comment`, `-- sql | `#DCDC` |
| FunctionsAA` | `print()`, `main()` |
| Classes | `#4EC9B0` | `class MyClass` |
| Variables | `#9CDCFE` | `$var`, `@decorator` |
| Numbers | `#B5CEA8` | `42`, `3.14` |
| Operators | `#D4D4D4` | `+`, `-`, `*` |

**Light Theme:**
| Element | Hex Code |
|---------|----------|
| Background | `#FFFFFF` |
| Editor Background | `#FAFAFA` |
| Primary Text | `#333333` |
| Comments | `#008000` |

#### Typography

**UI Elements:**
- Font Family: SF Pro (`systemFont`)
- Heading: 13pt semibold
- Body: 13pt regular
- Caption: 11pt regular

**Code Editor:**
- Font Family: SF Mono (`monospacedSystemFont(ofSize:)`)
- Base Size: 13pt (configurable 10–24pt)
- Line Height: 1.5 × font size (19.5pt at 13pt)
- Letter Spacing: 0 (system default)

**Status Bar:**
- Font: SF Pro 11pt
- Line Numbers: SF Mono 11pt, right-aligned, `#858585`

#### Spacing System (8pt Grid)

| Element | Value |
|---------|-------|
| Window Padding | 0pt (edge-to-edge) |
| Sidebar Width | 220pt |
| Sidebar Padding | 12pt horizontal, 8pt vertical |
| Sidebar Item Spacing | 4pt |
| Editor Left Margin (line numbers) | 48pt |
| Editor Horizontal Padding | 16pt |
| Status Bar Height | 24pt |
| Toolbar Height | Native (auto) |

### 2.3 Component Specifications

#### Sidebar

- **Width:** 220pt fixed
- **Collapsible:** Toggle via toolbar button or `Cmd+\`
- **Material:** `NSVisualEffectView` with `.sidebar` material
- **Blur:** System default (approximately 20px)
- **Opacity:** 1.0 with material blending

**Contents:**
1. **Document Section**
   - File name (truncated with ellipsis if > 20 chars)
   - File path (secondary text color)
   - Modified indicator (● orange)

2. **Language Section**
   - Dropdown selector: Python, Shell Script, SQL, Plain Text
   - Auto-detected badge

3. **Statistics Section**
   - Lines count
   - Characters count
   - Words count (optional)

#### Editor (NSTextView)

- **Text Container:** Full width, flexible height
- **Line Numbers:** Gutter on left, 48pt width, right-aligned numbers
- **Current Line Highlight:** Full row background (`#2D2D2D` dark / `#F5F5F5` light)
- **Selection:** Semi-transparent blue (`#264F78` at 50% opacity)
- **Cursor:** 2pt width, `#AEAFAD`, blink rate 530ms

**Scroll Behavior:**
- Native NSScrollView
- Smooth scrolling enabled
- No rubber-banding at document edges (system default)

#### Toolbar

- **Style:** Unified titlebar with toolbar
- **Position:** Top, native NSToolbar
- **Items:**
  - New Document (NSToolbarItem)
  - Open (NSToolbarItem)
  - Save (NSToolbarItem)
  - Flexible Space
  - Theme Selector (NSPopUpButton)
  - Settings (NSToolbarItem)

#### Status Bar

- **Height:** 24pt
- **Background:** `#252526` (dark) / `#F3F3F3` (light)
- **Divider:** 1pt line, `#3C3C3C` (dark) / `#E0E0E0` (light)

**Layout (left to right):**
```
Ln {line}, Col {col} | {language} | {encoding} | {lineEnding} | ● Modified
```

- Line/Column: SF Pro 11pt
- Language: SF Pro 11pt, clickable (opens language selector)
- Encoding: SF Pro 11pt, "UTF-8" (future: dropdown)
- Line Ending: SF Pro 11pt, "Unix (LF)", "Windows (CRLF)", "Mac (CR)"
- Modified: SF Pro 11pt, orange dot + "Modified" text

### 2.4 Animations

| Animation | Duration | Curve |
|-----------|----------|-------|
| Sidebar Toggle | 200ms | ease-out |
| Theme Switch | 150ms | ease-in-out |
| Find Bar Appear | 150ms | spring (damping: 0.8) |
| Status Bar Update | 100ms | linear |

---

## 3. Functional Requirements

### 3.1 Core Features

#### F1: Document Operations

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| New Document | Create empty untitled document | ✅ Implemented | P0 |
| Open File | Open via dialog, drag-drop, or Cmd+O | ✅ Implemented | P0 |
| Save File | Save to existing path | ✅ Implemented | P0 |
| Save As | Save to new path | ✅ Implemented | P0 |
| Recent Files | Track last 10 opened files | ✅ Implemented | P0 |
| Auto-save | Automatically save modified files | ✅ Implemented | P1 |
| Multiple Windows | Open same document in multiple windows | ✅ Implemented | P0 |
| Trim Trailing Whitespace | Remove trailing whitespace on save + manual command | ✅ Implemented | P1 |

#### F2: Text Editing

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Undo/Redo | Full undo stack via NSTextView | ✅ Implemented | P0 |
| Cut/Copy/Paste | Standard editing operations | ✅ Implemented | P0 |
| Select All | Select entire document | ✅ Implemented | P0 |
| Line Operations | Duplicate line, move line up/down | ✅ Implemented | P0 |
| Auto-indent | Maintain indentation on newline | ✅ Implemented | P0 |
| Tab/Shift+Tab | Insert/remove indentation | ✅ Implemented | P0 |
| Convert Indentation | Convert between tabs and spaces | ✅ Implemented | P1 |
| Bracket Matching | Highlight matching brackets when cursor on one | ✅ Implemented | P1 |

#### F3: Syntax Highlighting

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Python | Keywords, decorators, functions, strings, comments | ✅ Implemented | P0 |
| Shell Script | Keywords, variables, strings, comments | ✅ Implemented | P0 |
| SQL | Keywords, functions, strings, comments | ✅ Implemented | P0 |
| Auto-detect | Detect language from file extension | ✅ Implemented | P0 |
| Manual Select | Override detected language | ✅ Implemented | P0 |
| Incremental Update | Re-highlight only changed regions | ✅ Implemented | P0 |

#### F4: Find & Replace

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Find | Search with plain text | ✅ Implemented | P0 |
| Regex Find | Search with regular expressions | ✅ Implemented | P0 |
| Case Sensitive | Toggle case sensitivity | ✅ Implemented | P0 |
| Replace | Replace current match | ✅ Implemented | P0 |
| Replace All | Replace all matches | ✅ Implemented | P0 |
| Find Next/Previous | Navigate matches | ✅ Implemented | P0 |
| Highlight Matches | Visual highlight of all matches | ✅ Implemented | P0 |
| Find Selection | Search for selected text | ✅ Implemented | P1 |

#### F5: View Options

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Line Numbers | Toggle gutter numbers | ✅ Implemented | P0 |
| Current Line Highlight | Highlight active line | ✅ Implemented | P0 |
| Word Wrap | Wrap long lines | ✅ Implemented | P0 |
| Sidebar Toggle | Show/hide sidebar | ✅ Implemented | P0 |
| Theme Selection | Switch between themes | ✅ Implemented | P0 |
| Split View | Split editor horizontally or vertically | ✅ Implemented | P1 |
| Show Invisibles | Display spaces, tabs as visible characters | ✅ Implemented | P1 |
| Line Length Guide | Show vertical guide at specified column | ✅ Implemented | P1 |
| Highlight Trailing Whitespace | Highlight trailing whitespace in subtle red | ✅ Implemented | P1 |

#### F6: Themes

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Dark Theme | Default dark theme | ✅ Implemented | P0 |
| Light Theme | Light theme | ✅ Implemented | P0 |
| Monokai | Monokai color scheme | ✅ Implemented | P0 |
| Dracula | Dracula color scheme | ✅ Implemented | P0 |
| Midnight | Midnight color scheme | ✅ Implemented | P0 |
| Custom Theme | User-defined colors | ✅ Implemented | P0 |
| Sync with System | Follow macOS appearance | ✅ Implemented | P0 |

#### F7: Tab Management

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Multiple Tabs | Open multiple files in tabs | ✅ Implemented | P0 |
| Tab Bar | Visual tab bar above editor | ✅ Implemented | P0 |
| New Tab | Create new tab | ✅ Implemented | P0 |
| Close Tab | Close current tab | ✅ Implemented | P0 |
| Reorder Tabs | Drag to reorder | ~ Deferred | P0 |

#### F8: Code Folding

| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Fold Functions | Collapse function bodies | ✅ Implemented | P0 |
| Fold Classes | Collapse class definitions | ✅ Implemented | P0 |
| Fold Comments | Collapse block comments | ✅ Implemented | P0 |
| Fold Indented | Collapse indented blocks | ✅ Implemented | P0 |
| Fold Indicators | Visual indicators in gutter | ✅ Implemented | P0 |
| Fold All/Unfold | Bulk fold operations | ✅ Implemented | P0 |

### 3.2 Keyboard Shortcuts

| Shortcut | Action | Status |
|----------|--------|--------|
| Cmd+N | New Document | ✅ |
| Cmd+O | Open Document | ✅ |
| Cmd+S | Save | ✅ |
| Cmd+Shift+S | Save As | ✅ |
| Cmd+W | Close Window | ✅ |
| Cmd+Q | Quit | ✅ |
| Cmd+F | Find | ✅ |
| Cmd+G | Find Next | ✅ |
| Cmd+Shift+G | Find Previous | ✅ |
| Cmd+H | Replace | ✅ |
| Cmd+, | Settings | ✅ |
| Cmd+P | Quick Open | ✅ |
| Cmd+\\ | Toggle Sidebar | ✅ |
| Cmd+L | Go to Line | ✅ |
| Cmd+Shift+L | Select Line | ✅ |
| Cmd+D | Duplicate Line | ✅ |
| Cmd+Shift+D | Move Line Down | ✅ |
| Cmd+Shift+Up | Move Line Up | ✅ |
| Cmd+Shift+Down | Move Line Down | ✅ |
| Cmd+/ | Toggle Comment | ✅ |
| Cmd+Tab | Next Tab | ✅ |
| Cmd+Shift+Tab | Previous Tab | ✅ |
| Cmd+Shift+] | Next Tab (alt) | ✅ |
| Cmd+Shift+[ | Previous Tab (alt) | ✅ |
| Cmd+Shift+U | Uppercase Selection | ✅ |
| Cmd+Opt+U+Shift | Lowercase Selection | ✅ |
| Cmd+Opt+S | Sort Lines | ✅ |
| Cmd+Shift+I | Show Invisibles | ✅ |
| Cmd+Shift+Option+T | Trim Trailing Whitespace | ✅ |
| Cmd+E | Find Selection | ✅ |
| Cmd+Shift+\ | Convert to Spaces | ✅ |
| Cmd+Option+\ | Convert to Tabs | ✅ |
| (Automatic) | Auto-save | ✅ |
| (Visual) | Line Length Guide | ✅ |

---

## 4. Gap Analysis Checklist

### Instructions

For each item:
- **[✓]** = Fully implemented and tested
- **[~]** = Partially implemented (known gaps)
- **[✗]** = Not implemented

Mark each item against the current codebase to identify work required.

### Core Functionality

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.1 | New Document | [✓] | Implemented in EditorViewModel |
| 4.2 | Open File | [✓] | NSOpenPanel integration |
| 4.3 | Save File | [✓] | Write to URL |
| 4.4 | Save As | [✓] | NSSavePanel integration |
| 4.5 | Recent Files | [✓] | recentFiles in ThemeManager + Sidebar |
| 4.5a | Trim Trailing Whitespace | [✓] | trimTrailingWhitespace in EditorViewModel |
| 4.6 | Multiple Windows | [✓] | SwiftUI WindowGroup provides Cmd+Shift+N |
| 4.7 | Undo/Redo | [✓] | NSTextView built-in |
| 4.8 | Cut/Copy/Paste | [✓] | NSTextView built-in |
| 4.9 | Line Operations | [✓] | duplicateLine/moveLineUp/moveLineDown in EditorViewModel |
| 4.10 | Auto-indent | [✓] | shouldInsertText in EditorView |
| 4.11 | Tab/Shift+Tab | [✓] | Implemented |
| 4.11a | Bracket Matching | [✓] | highlightMatchingBracket in EditorView Coordinator |
| 4.11b | Word/Character Count | [✓] | wordCount, characterCount in StatusBarView |
| 4.11c | Uppercase/Lowercase | [✓] | uppercaseSelection/lowercaseSelection in EditorViewModel |
| 4.11d | Sort Lines | [✓] | sortLines in EditorViewModel, sorts selected lines alphabetically |

### Syntax Highlighting

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.12 | Python Support | [✓] | Regex-based in SyntaxHighlighter |
| 4.13 | Shell Script | [✓] | Regex-based in SyntaxHighlighter |
| 4.14 | SQL Support | [✓] | Regex-based in SyntaxHighlighter |
| 4.15 | Auto-detect Language | [✓] | ProgrammingLanguage.fromExtension |
| 4.16 | Manual Language Select | [✓] | Sidebar dropdown |
| 4.17 | Incremental Highlight | [✓] | Only re-highlights changed line |

### Find & Replace

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.18 | Find | [✓] | FindBarView |
| 4.19 | Regex Find | [✓] | NSRegularExpression |
| 4.20 | Case Sensitive | [✓] | Option in FindBar |
| 4.21 | Replace | [✓] | replaceNext in EditorViewModel |
| 4.22 | Replace All | [✓] | replaceAll in EditorViewModel |
| 4.23 | Find Next/Previous | [✓] | findNext/findPrevious in EditorViewModel |
| 4.24 | Highlight Matches | [✓] | highlightMatches in EditorViewModel |

### View Options

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.25 | Line Numbers | [✓] | EditorView gutter |
| 4.26 | Current Line Highlight | [✓] | EditorView coordinator |
| 4.27 | Word Wrap | [✓] | NSTextContainer in updateNSView |
| 4.28 | Sidebar Toggle | [✓] | Cmd+\\ works |
| 4.29 | Theme Selection | [✓] | ThemeManager + Settings |
| 4.30 | Split View | [✓] | SplitMode enum in ContentView |
| 4.30a | Show Invisibles | [✓] | layoutManager.showsInvisibleCharacters in EditorView, settings toggle |
| 4.30b | Highlight Trailing Whitespace | [✓] | applyTrailingWhitespaceHighlighting in EditorView, settings toggle |

### Themes

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.30 | Dark Theme | [✓] | EditorTheme.dark |
| 4.31 | Light Theme | [✓] | EditorTheme.light |
| 4.32 | Monokai | [✓] | EditorTheme.monokai |
| 4.33 | Dracula | [✓] | EditorTheme.dracula |
| 4.34 | Midnight | [✓] | EditorTheme.midnight |
| 4.35 | Custom Theme | [✓] | importTheme/exportTheme in ThemeManager |
| 4.36 | System Sync | [✓] | updateForSystemAppearance in ThemeManager |

### Tab Management

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.37 | Multiple Tabs | [✓] | SwiftUI state in ContentView |
| 4.38 | Tab Bar | [✓] | TabBarView component |
| 4.39 | New Tab | [✓] | Cmd+T in MyTextApp |
| 4.40 | Close Tab | [✓] | Cmd+W in MyTextApp |
| 4.41 | Reorder Tabs | [✗] | Drag and drop |

### Code Folding

| ID | Feature | Current Status | Implementation Notes |
|----|---------|----------------|---------------------|
| 4.42 | Fold Functions | [✓] | detectFoldRegions in SyntaxHighlighter |
| 4.43 | Fold Classes | [✓] | detectFoldRegions in SyntaxHighlighter |
| 4.44 | Fold Comments | [✓] | detectFoldRegions in SyntaxHighlighter |
| 4.45 | Fold Indented | [✓] | detectFoldRegions in SyntaxHighlighter |
| 4.46 | Fold Indicators | [✓] | FoldIndicatorView in EditorView |
| 4.47 | Fold All/Unfold | [✓] | foldAll/unfoldAll in EditorViewModel |

---

## 5. UI Component Guide

### 5.1 Implementation Checklist for Premium Look

**Colors:**
- [ ] Use exact hex codes from Section 2.2
- [ ] Define semantic colors in ThemeManager
- [ ] Support both dark and light variants

**Typography:**
- [ ] SF Pro for all UI text
- [ ] SF Mono for code and line numbers
- [ ] 13pt base, configurable size
- [ ] 1.5× line height for code

**Spacing:**
- [ ] 8pt grid alignment
- [ ] 220pt sidebar width
- [ ] 48pt line number gutter
- [ ] 16pt editor padding

**Vibrancy:**
- [ ] NSVisualEffectView for sidebar
- [ ] Use `.sidebar` material
- [ ] Test on macOS 14+ ( Sonoma )
- [ ] Test on macOS 13 ( Ventura )

**Animations:**
- [ ] 200ms sidebar toggle
- [ ] Test with Animation.easeOut
- [ ] Disable animations in Reduce Motion

### 5.2 Component Hierarchy

```
App
├── WindowGroup
│   └── ContentView
│       ├── ToolbarView
│       │   ├── NewButton
│       │   ├── OpenButton
│       │   ├── SaveButton
│       │   ├── ThemePicker
│       │   └── SettingsButton
│       ├── HSplitView
│       │   ├── SidebarView (collapsible)
│       │   │   ├── DocumentInfoSection
│       │   │   ├── LanguageSelectorSection
│       │   │   └── StatisticsSection
│       │   └── EditorContainer
│       │       ├── EditorView
│       │       │   ├── LineNumbersView
│       │       │   └── TextEditorView (NSTextView)
│       │       └── FindBarView (conditional)
│       └── StatusBarView
```

### 5.3 SwiftUI + AppKit Bridge

| Component | Implementation | Notes |
|-----------|----------------|-------|
| Main Window | SwiftUI ContentView | WindowGroup |
| Text Editor | NSViewRepresentable → NSTextView | Core editing |
| Toolbar | Native NSToolbar | Best integration |
| Sidebar | SwiftUI + VisualEffectView | Vibrancy |
| Find Bar | SwiftUI overlay | Transient |
| Status Bar | SwiftUI fixed bottom | Simple view |

### 5.4 Asset Requirements

| Asset | Specification |
|-------|---------------|
| App Icon | 16, 32, 64, 128, 256, 512, 1024px |
| Toolbar Icons | SF Symbols (system) |
| Document Icon | Custom or SF Symbol |

---

## 6. Architecture Notes

### Current Architecture (v1.0)

- **Pattern:** MVVM with SwiftUI
- **Text Engine:** NSTextView wrapped in NSViewRepresentable
- **State:** @Published in EditorViewModel
- **Persistence:** UserDefaults

### Recommended Refinements

1. **Document Model:** Consider SwiftUI Document architecture for native file handling
2. **Text Storage:** NSTextStorage subclass for custom highlighting
3. **Undo Management:** Leverage NSTextView's built-in undo coordinator
4. **Threading:** Keep all UI on @MainActor, background for file I/O

---

## 7. Testing Requirements

### Performance Targets

| Metric | Target |
|--------|--------|
| App Launch | < 500ms to interactive |
| File Open (10K lines) | < 100ms |
| File Open (100K lines) | < 1s |
| Syntax Highlight (10K lines) | < 200ms |
| Keystroke Response | < 16ms (60fps) |
| Memory (100K lines) | < 200MB |

### Compatibility

- **macOS 14.0+** (Sonoma) — Primary target
- **macOS 13.0+** (Ventura) — Minimum supported
- **Apple Silicon** — Native arm64
- **Intel** — Compatibility build (if needed)

---

*Document Version: 2.0.0*
*Created: 2026-03-09*
*Purpose: Technical specification and gap analysis benchmark for MyText premium text editor*
