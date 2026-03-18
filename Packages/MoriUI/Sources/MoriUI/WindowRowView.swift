import SwiftUI
import MoriCore

/// A row representing a single tmux window within a worktree section.
public struct WindowRowView: View {
    let window: RuntimeWindow
    let isActive: Bool
    let onSelect: () -> Void

    public init(
        window: RuntimeWindow,
        isActive: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.window = window
        self.isActive = isActive
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.caption)
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)

                Text(window.title.isEmpty ? "Window \(window.tmuxWindowIndex)" : window.title)
                    .font(.body)
                    .lineLimit(1)

                Spacer()

                if isActive {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isActive ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
