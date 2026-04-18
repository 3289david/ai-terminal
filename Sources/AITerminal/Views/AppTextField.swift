import SwiftUI
import AppKit

/// NSViewRepresentable text field for reliable keyboard input on macOS.
/// Fixes SwiftUI TextField focus issues in complex view hierarchies
/// (NavigationSplitView + HSplitView) where @Observable triggers
/// updateNSView constantly, fighting with the field editor.
struct AppTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    var textColor: NSColor = NSColor(red: 0.902, green: 0.929, blue: 0.953, alpha: 1.0)
    var onSubmit: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onTab: (() -> Void)?
    var onEscape: (() -> Void)?
    var autoFocus: Bool = false
    var focusTrigger: Int = 0

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let tf = FocusableTextField()
        tf.delegate = context.coordinator
        tf.font = font
        tf.textColor = textColor
        tf.backgroundColor = .clear
        tf.drawsBackground = false
        tf.isBordered = false
        tf.isBezeled = false
        tf.focusRingType = .none
        tf.usesSingleLineMode = true
        tf.maximumNumberOfLines = 1
        tf.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(white: 0.35, alpha: 1.0),
                .font: font
            ]
        )
        tf.lineBreakMode = .byTruncatingTail
        tf.cell?.isScrollable = true
        tf.cell?.sendsActionOnEndEditing = false
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.textField = tf
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // CRITICAL: Update binding reference every time SwiftUI recreates
        // the struct. Without this, the coordinator holds a stale binding
        // from makeCoordinator() and typing writes to a dead reference.
        context.coordinator.binding = _text

        // Always keep coordinator's closures current
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onUpArrow = onUpArrow
        context.coordinator.onDownArrow = onDownArrow
        context.coordinator.onTab = onTab
        context.coordinator.onEscape = onEscape

        // CRITICAL: Only push text if the user is NOT actively editing.
        // When the field editor is active and we set stringValue, it kills
        // the cursor position and interrupts typing.
        let isEditing = context.coordinator.isEditing
        if !isEditing && nsView.stringValue != text {
            nsView.stringValue = text
        }

        // Auto-focus on first window appearance
        if autoFocus && !context.coordinator.hasFocused {
            if nsView.window != nil {
                context.coordinator.hasFocused = true
                DispatchQueue.main.async {
                    nsView.window?.makeFirstResponder(nsView)
                }
            }
        }

        // Manual focus trigger (e.g., after clicking terminal output)
        if context.coordinator.lastFocusTrigger != focusTrigger {
            context.coordinator.lastFocusTrigger = focusTrigger
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        weak var textField: NSTextField?
        var onSubmit: (() -> Void)?
        var onUpArrow: (() -> Void)?
        var onDownArrow: (() -> Void)?
        var onTab: (() -> Void)?
        var onEscape: (() -> Void)?
        var hasFocused = false
        var lastFocusTrigger = 0
        var isEditing = false
        var binding: Binding<String>

        init(_ parent: AppTextField) {
            self.binding = parent._text
            self.onSubmit = parent.onSubmit
            self.onUpArrow = parent.onUpArrow
            self.onDownArrow = parent.onDownArrow
            self.onTab = parent.onTab
            self.onEscape = parent.onEscape
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            // Sync final value
            if let tf = obj.object as? NSTextField {
                binding.wrappedValue = tf.stringValue
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            binding.wrappedValue = tf.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                isEditing = false
                onSubmit?()
                // Force sync NSTextField to binding after submit clears it
                DispatchQueue.main.async { [weak self] in
                    if let tf = self?.textField {
                        tf.stringValue = self?.binding.wrappedValue ?? ""
                    }
                }
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                if let handler = onUpArrow {
                    handler()
                    // Sync the text back after history navigation
                    DispatchQueue.main.async { [weak self] in
                        if let tf = self?.textField {
                            tf.stringValue = self?.binding.wrappedValue ?? ""
                            // Move cursor to end
                            tf.currentEditor()?.selectedRange = NSRange(
                                location: tf.stringValue.count, length: 0
                            )
                        }
                    }
                    return true
                }
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                if let handler = onDownArrow {
                    handler()
                    DispatchQueue.main.async { [weak self] in
                        if let tf = self?.textField {
                            tf.stringValue = self?.binding.wrappedValue ?? ""
                            tf.currentEditor()?.selectedRange = NSRange(
                                location: tf.stringValue.count, length: 0
                            )
                        }
                    }
                    return true
                }
            }
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                if let handler = onTab {
                    handler()
                    return true
                }
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                if let handler = onEscape {
                    handler()
                    return true
                }
            }
            return false
        }
    }
}

/// Custom NSTextField that prevents focus from being stolen by buttons
/// and ensures the field editor stays active.
final class FocusableTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        // Ensure cursor is visible
        if result, let editor = currentEditor() {
            editor.selectedRange = NSRange(location: stringValue.count, length: 0)
        }
        return result
    }
}
