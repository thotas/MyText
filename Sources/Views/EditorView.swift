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

        // Apply initial highlighting with a delay
        let coordinator = context.coordinator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            coordinator.applyHighlighting(to: textView)
        }

        // Set delegate after everything is configured
        textView.delegate = coordinator

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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SimpleTextEditor
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: SimpleTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update document
            parent.viewModel.updateContent(textView.string)

            // Cancel any pending highlight
            highlightWorkItem?.cancel()

            // Schedule highlighting with debounce
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyHighlighting(to: textView)
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        func applyHighlighting(to textView: NSTextView) {
            let language = parent.viewModel.detectedLanguage

            // Skip highlighting for plain text
            guard language != .plainText else { return }

            let theme = parent.themeManager.currentTheme

            // Get highlighted text
            let highlighted = parent.viewModel.syntaxHighlighter.highlight(
                textView.string,
                language: language,
                theme: theme
            )

            // Only apply if different
            if let currentAttr = textView.textStorage?.mutableCopy() as? NSMutableAttributedString {
                if !currentAttr.isEqual(to: highlighted) {
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
    }
}
