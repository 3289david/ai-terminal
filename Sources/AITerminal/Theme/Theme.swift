import SwiftUI

// MARK: - Color Palette (GitHub Dark-inspired)

enum Theme {
    // Backgrounds
    static let windowBackground     = Color(hex: "0F0F1A")
    static let terminalBackground   = Color(hex: "0D1117")
    static let panelBackground      = Color(hex: "161B22")
    static let sidebarBackground    = Color(hex: "0D1117")
    static let cardBackground       = Color(hex: "1C2333")
    static let inputBackground      = Color(hex: "21262D")

    // Text
    static let textPrimary   = Color(hex: "E6EDF3")
    static let textSecondary = Color(hex: "8B949E")
    static let textMuted     = Color(hex: "484F58")

    // Accents
    static let accent       = Color(hex: "58A6FF")
    static let accentGreen  = Color(hex: "3FB950")
    static let accentRed    = Color(hex: "F85149")
    static let accentOrange = Color(hex: "D29922")
    static let accentPurple = Color(hex: "BC8CFF")
    static let accentCyan   = Color(hex: "39D2C0")

    // Borders
    static let border        = Color(hex: "30363D")
    static let borderFocused = Color(hex: "58A6FF").opacity(0.5)

    // Fonts
    static let terminalFont      = Font.system(size: 13, design: .monospaced)
    static let terminalFontSmall = Font.system(size: 11, design: .monospaced)
    static let codeFont          = Font.system(size: 12, design: .monospaced)
    static let headingFont       = Font.system(size: 15, weight: .semibold)
    static let bodyFont          = Font.system(size: 13)
    static let captionFont       = Font.system(size: 11)
    static let badgeFont         = Font.system(size: 10, weight: .medium)

    // Spacing
    static let paddingSmall: CGFloat    = 6
    static let paddingMedium: CGFloat   = 12
    static let paddingLarge: CGFloat    = 20
    static let cornerRadius: CGFloat    = 8
    static let cornerRadiusSmall: CGFloat = 4
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.paddingMedium)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
