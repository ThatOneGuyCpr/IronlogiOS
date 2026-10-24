import SwiftUI
import UIKit

// MARK: - Glacier palette (adapts to light and dark)

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    static func dyn(_ light: UInt32, _ dark: UInt32, la: CGFloat = 1, da: CGFloat = 1) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: da) : UIColor(hex: light, alpha: la)
        })
    }
}

enum Theme {
    static let bg = Color.dyn(0xEDF3FA, 0x07111F)
    static let blob1 = Color.dyn(0xC9DFF8, 0x123462)
    static let blob2 = Color.dyn(0xD8E8FB, 0x0C2443)
    static let card = Color.dyn(0xFFFFFF, 0xFFFFFF, la: 0.82, da: 0.065)
    static let cardBorder = Color.dyn(0xFFFFFF, 0xFFFFFF, la: 0.95, da: 0.11)
    static let ink = Color.dyn(0x0B1B2E, 0xF2F6FB)
    static let sub = Color.dyn(0x4A5D73, 0xA9B8CA)
    static let faint = Color.dyn(0xE4ECF5, 0xFFFFFF, da: 0.08)
    static let chip = Color.dyn(0xEEF3F9, 0xFFFFFF, da: 0.08)
    static let accent = Color.dyn(0x1F6FEB, 0x4C9BFF)
    static let accentInk = Color.dyn(0xFFFFFF, 0x05101F)
    static let accentSoft = Color.dyn(0xE1EDFD, 0x4C9BFF, da: 0.17)
    static let accentText = Color.dyn(0x1558C0, 0x8DC0FF)
    static let field = Color.dyn(0xF4F8FC, 0xFFFFFF, da: 0.07)
    static let fieldBorder = Color.dyn(0xCCDAEA, 0xFFFFFF, da: 0.16)
    static let good = Color.dyn(0x15803D, 0x34C759)
    static let goodInk = Color.dyn(0xFFFFFF, 0x05210E)
    static let goodRow = Color.dyn(0xEAF7EF, 0x34C759, da: 0.10)
    static let goodText = Color.dyn(0x15803D, 0x5BD68A)
    static let warn = Color.dyn(0xB42318, 0xFF8A80)
    static let promptBg = Color.dyn(0xDCEAFD, 0x4C9BFF, da: 0.14)
    static let promptBorder = Color.dyn(0xBCD5F7, 0x4C9BFF, da: 0.35)
    static let video = Color.dyn(0x2B5FA8, 0x1A3A66)
    static let shadow = Color.dyn(0x102A4D, 0x000000, la: 0.08, da: 0.35)

    // Kept so older call sites still compile.
    static let sky = accent
}

// MARK: - Background

struct SkyBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            GeometryReader { geo in
                Circle()
                    .fill(RadialGradient(colors: [Theme.blob1, Theme.blob1.opacity(0)], center: .center, startRadius: 0, endRadius: 220))
                    .frame(width: 440, height: 440)
                    .position(x: 60, y: 60)
                Circle()
                    .fill(RadialGradient(colors: [Theme.blob2, Theme.blob2.opacity(0)], center: .center, startRadius: 0, endRadius: 220))
                    .frame(width: 440, height: 440)
                    .position(x: geo.size.width + 20, y: geo.size.height * 0.62)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Cards

struct GlacierCard: ViewModifier {
    var radius: CGFloat = 24
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
            .shadow(color: Theme.shadow, radius: 14, x: 0, y: 6)
    }
}

extension View {
    func glacierCard(radius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        modifier(GlacierCard(radius: radius, padding: padding))
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Theme.ink)
    }
}

struct Pill: View {
    let text: String
    var fill: Color = Theme.accentSoft
    var ink: Color = Theme.accentText

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(fill, in: Capsule())
            .foregroundStyle(ink)
    }
}

/// Solid accent button used for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(Theme.accentInk)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Outlined secondary button.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(configuration.isPressed ? Theme.chip : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.fieldBorder, lineWidth: 1))
            .foregroundStyle(Theme.ink)
    }
}

/// Identifiable wrappers for sheet(item:).
struct IndexBox: Identifiable { let id: Int }
struct IDBox: Identifiable { let id: String }

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension Prescription {
    func summary(for ex: Exercise) -> String {
        "\(sets) × \(rangeText)\(ex.timed ? "s" : "")\(ex.perSide ? " per side" : "") · \(rest)s rest"
    }

    func short(for ex: Exercise) -> String {
        "\(sets) × \(rangeText)\(ex.timed ? "s" : "") · \(rest)s"
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
