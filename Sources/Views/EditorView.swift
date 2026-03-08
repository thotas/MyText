import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    var body: some View {
        SimpleTextEditor(viewModel: viewModel, themeManager: themeManager)
            .background(Color(themeManager.currentTheme.editorBackground))
    }
}

struct SimpleTextEditor: NSViewRepresentable {
    @ObservedObject var viewModel: EditorViewModel
    var themeManager: ThemeManager

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure text view
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFontPanel = false

        // Disable auto substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false

        // Configure appearance
        textView.backgroundColor = NSColor(Color(themeManager.currentTheme.editorBackground))
        textView.insertionPointColor = NSColor(Color(themeManager.currentTheme.cursor))
        textView.textColor = NSColor(Color(themeManager.currentTheme.text))

        // Configure font
        let fontSize = ThemeManager.shared.fontSize()
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Configure layout
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Set initial content
        textView.string = viewModel.document.content

        // Apply initial highlighting
        DispatchQueue.main.async {
            context.coordinator.applyHighlighting(to: textView)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Update appearance based on theme
        textView.backgroundColor = NSColor(Color(themeManager.currentTheme.editorBackground))
        textView.insertionPointColor = NSColor(Color(themeManager.currentTheme.cursor))

        // Update font
        let fontSize = ThemeManager.shared.fontSize()
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Update content if different
        if textView.string != viewModel.document.content {
            let selectedRange = textView.selectedRange()
            textView.string = viewModel.document.content
            context.coordinator.applyHighlighting(to: textView)

            // Restore selection
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // Update cursor position in view model
        let cursorPosition = textView.selectedRange().location
        viewModel.editorState.cursorPosition = cursorPosition
        viewModel.updateCursorPosition()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor

        init(_ parent: SimpleTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update document
            parent.viewModel.updateContent(textView.string)

            // Apply syntax highlighting
            applyHighlighting(to: textView)
        }

        func applyHighlighting(to textView: NSTextView) {
            let language = parent.viewModel.detectedLanguage
            let theme = parent.themeManager.currentTheme

            let highlighted = parent.viewModel.syntaxHighlighter.highlight(
                textView.string,
                language: language,
                theme: theme
            )

            // Preserve selection
            let selectedRange = textView.selectedRange()

            // Apply highlighting
            textView.textStorage?.setAttributedString(highlighted)

            // Restore selection
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }
}
