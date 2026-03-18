import SwiftUI
import MoriCore

/// Narrow rail displaying projects as first-letter circle icons with names.
public struct ProjectRailView: View {
    private let projects: [Project]
    private let selectedProjectId: UUID?
    private let onSelect: (UUID) -> Void

    public init(
        projects: [Project],
        selectedProjectId: UUID?,
        onSelect: @escaping (UUID) -> Void
    ) {
        self.projects = projects
        self.selectedProjectId = selectedProjectId
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                ForEach(projects) { project in
                    ProjectRailRow(
                        project: project,
                        isSelected: project.id == selectedProjectId,
                        onSelect: { onSelect(project.id) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Row

private struct ProjectRailRow: View {
    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Text(firstLetter)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }

                Text(project.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var firstLetter: String {
        String(project.name.prefix(1)).uppercased()
    }
}
