import SwiftUI
import AppKit

/// Centralized design tokens for consistent styling across MoriUI views.
public enum MoriTokens {

    // MARK: - Colors

    public enum Color {
        public static let error = SwiftUI.Color.red
        public static let success = SwiftUI.Color.green
        public static let warning = SwiftUI.Color.orange
        public static let attention = SwiftUI.Color.yellow
        public static let info = SwiftUI.Color.blue
        public static let active = SwiftUI.Color.accentColor
        public static let inactive = SwiftUI.Color.gray
        public static let muted = SwiftUI.Color.secondary
    }

    // MARK: - Spacing

    public enum Spacing {
        /// 1pt — hairline spacing (e.g., between arrow icon and count)
        public static let xxs: CGFloat = 1
        /// 2pt — tightest spacing (e.g., between swatch circles)
        public static let xs: CGFloat = 2
        /// 4pt — compact spacing (e.g., between badges, inner padding)
        public static let sm: CGFloat = 4
        /// 6pt — default element spacing (e.g., HStack items in a row)
        public static let md: CGFloat = 6
        /// 8pt — section/group spacing (e.g., vertical padding, rail items)
        public static let lg: CGFloat = 8
        /// 12pt — generous padding (e.g., header horizontal padding)
        public static let xl: CGFloat = 12
        /// 16pt — indent/large gaps (e.g., window row indent under worktree)
        public static let xxl: CGFloat = 16
        /// 40pt — large empty state offset
        public static let emptyState: CGFloat = 40
    }

    // MARK: - Corner Radius

    public enum Radius {
        /// 4pt — default for rows, badges, previews
        public static let small: CGFloat = 4
        /// 8pt — cards, panels
        public static let medium: CGFloat = 8
    }

    // MARK: - Icon Sizes

    public enum Icon {
        /// 10pt — badge icons (error, waiting, running, etc.)
        public static let badge: CGFloat = 10
        /// 8pt — status indicator dots, arrow icons
        public static let indicator: CGFloat = 8
        /// 6pt — small dots (unread, active marker, dirty)
        public static let dot: CGFloat = 6
    }

    // MARK: - Sizes

    public enum Size {
        /// 36pt — project rail avatar circle
        public static let avatar: CGFloat = 36
        /// 16pt — avatar icon font size
        public static let avatarFont: CGFloat = 16
        /// 13pt — font picker preview size
        public static let fontPreview: CGFloat = 13
        /// 10pt — theme swatch circle
        public static let swatch: CGFloat = 10
        /// 20pt — theme preview bar height
        public static let previewBar: CGFloat = 20
    }

    // MARK: - Typography

    public enum Font {
        /// Section header (e.g., "Worktrees")
        public static let sectionTitle = SwiftUI.Font.subheadline.weight(.semibold)
        /// Worktree row name
        public static let rowTitle = SwiftUI.Font.headline
        /// Window row name
        public static let windowTitle = SwiftUI.Font.body
        /// Small labels, icons, branch icon
        public static let label = SwiftUI.Font.caption
        /// Smallest labels (project name under avatar)
        public static let caption = SwiftUI.Font.caption2
        /// Badge count text
        public static let badgeCount = SwiftUI.Font.system(size: 9, weight: .bold, design: .rounded)
        /// Ahead/behind count
        public static let monoSmall = SwiftUI.Font.system(size: 10, design: .monospaced)
        /// Ahead/behind arrow
        public static let arrowIcon = SwiftUI.Font.system(size: 8)
    }

    // MARK: - Opacity

    public enum Opacity {
        /// 0.08 — subtle highlight (e.g., active window row)
        public static let subtle: Double = 0.08
        /// 0.12 — light highlight (e.g., selected worktree row)
        public static let light: Double = 0.12
        /// 0.2 — medium highlight (e.g., unselected avatar circle)
        public static let medium: Double = 0.2
    }
}

// MARK: - Hex Color Helper (package-internal)

/// Converts a hex color string to NSColor. Used by sidebar and settings views.
func nsColor(hex: String) -> NSColor {
    let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let scanner = Scanner(string: h)
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)

    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}
