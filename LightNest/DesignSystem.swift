import SwiftUI

// MARK: - Color System
extension Color {
    // Backgrounds
    static let bgPrimary = Color(hex: "#0F172A")
    static let bgDepth = Color(hex: "#111827")
    static let bgSoft = Color(hex: "#1A1F2E")
    static let cardBg = Color(hex: "#1E293B")
    static let cardHover = Color(hex: "#263244")
    static let divider = Color(hex: "#334155")

    // Accent Yellow
    static let accentYellow = Color(hex: "#FACC15")
    static let accentYellowActive = Color(hex: "#EAB308")
    static let accentYellowLight = Color(hex: "#FDE047")

    // Accent Orange
    static let accentOrange = Color(hex: "#F97316")
    static let accentOrangeSoft = Color(hex: "#FB923C")
    static let accentOrangeLight = Color(hex: "#FDBA74")

    // Accent Blue
    static let accentBlue = Color(hex: "#3B82F6")
    static let accentBlueSoft = Color(hex: "#60A5FA")

    // Status
    static let statusDone = Color(hex: "#22C55E")
    static let statusInProgress = Color(hex: "#3B82F6")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusError = Color(hex: "#EF4444")

    // Text
    static let textPrimary = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textInactive = Color(hex: "#64748B")

    // Glow
    static let glowYellow = Color(hex: "#FACC15").opacity(0.35)
    static let glowOrange = Color(hex: "#F97316").opacity(0.3)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - App State
class AppState: ObservableObject {
    @AppStorage("appTheme") var theme: String = "dark"
    @AppStorage("appCurrency") var currency: String = "USD"
    @AppStorage("appUnits") var units: String = "metric"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
}

// MARK: - Gradient Helpers
extension LinearGradient {
    static let yellowGlow = LinearGradient(
        colors: [Color.accentYellow, Color.accentOrange],
        startPoint: .leading, endPoint: .trailing
    )
    static let cardGradient = LinearGradient(
        colors: [Color.cardBg, Color.bgSoft],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bgGradient = LinearGradient(
        colors: [Color.bgPrimary, Color.bgDepth],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                ? Color.accentYellowActive
                : Color.accentYellow
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.divider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(configuration.isPressed ? Color.statusError.opacity(0.8) : Color.statusError)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.divider, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Status Color Helper
func statusColor(_ status: String) -> Color {
    switch status.lowercased() {
    case "done", "completed", "active": return .statusDone
    case "in progress", "planning": return .statusInProgress
    case "warning", "attention": return .statusWarning
    case "error", "overdue": return .statusError
    default: return .textSecondary
    }
}
