import SwiftUI
import UIKit

/// Accent color themes. Shared by the app, the widgets and the Live Activity.
/// The app saves the chosen id to the App Group so widgets can read it.
struct Palette: Identifiable {
    let id: String
    let name: String
    let accent: (UInt32, UInt32)
    let accentInk: (UInt32, UInt32)
    let accentText: (UInt32, UInt32)
    let softLight: UInt32
    let bg: (UInt32, UInt32)
    let blob1: (UInt32, UInt32)
    let blob2: (UInt32, UInt32)
    let promptLight: (bg: UInt32, border: UInt32)
    let video: (UInt32, UInt32)
    /// Widget background gradient: top and bottom, light then dark.
    let widgetTop: (UInt32, UInt32)
    let widgetBottom: (UInt32, UInt32)

    static let defaultsKey = "accentPalette"

    static let all: [Palette] = [
        Palette(id: "glacier", name: "Glacier",
                accent: (0x1F6FEB, 0x4C9BFF), accentInk: (0xFFFFFF, 0x05101F), accentText: (0x1558C0, 0x8DC0FF),
                softLight: 0xE1EDFD, bg: (0xEDF3FA, 0x07111F), blob1: (0xC9DFF8, 0x123462), blob2: (0xD8E8FB, 0x0C2443),
                promptLight: (0xDCEAFD, 0xBCD5F7), video: (0x2B5FA8, 0x1A3A66),
                widgetTop: (0xFFFFFF, 0x0F2342), widgetBottom: (0xE6F0FC, 0x0A1830)),
        Palette(id: "ember", name: "Ember",
                accent: (0xD9530B, 0xFF8A3D), accentInk: (0xFFFFFF, 0x1F0A00), accentText: (0xB0440A, 0xFFB27A),
                softLight: 0xFDE8DA, bg: (0xFAF2EC, 0x140A05), blob1: (0xF8D9C4, 0x4A1E08), blob2: (0xFBE6D8, 0x2E1206),
                promptLight: (0xFDE3D2, 0xF7C7A6), video: (0xA8481A, 0x66290A),
                widgetTop: (0xFFFFFF, 0x2A1208), widgetBottom: (0xFCEADF, 0x170904)),
        Palette(id: "gold", name: "Gold",
                accent: (0xA86E12, 0xF2B33D), accentInk: (0xFFFFFF, 0x1E1300), accentText: (0x8A5A0E, 0xF7CD7A),
                softLight: 0xF7ECD6, bg: (0xF7F2E8, 0x110C04), blob1: (0xF0DFBB, 0x3D2A08), blob2: (0xF5E9CF, 0x261A05),
                promptLight: (0xF5E7C8, 0xEBD3A0), video: (0x8A5A12, 0x4D3308),
                widgetTop: (0xFFFFFF, 0x261A07), widgetBottom: (0xF6EDDA, 0x140D03)),
        Palette(id: "volt", name: "Volt",
                accent: (0x4A7A0C, 0xC6F432), accentInk: (0xFFFFFF, 0x0E1A00), accentText: (0x3D6606, 0xD4FF5C),
                softLight: 0xE6F2D3, bg: (0xF1F5EA, 0x090D04), blob1: (0xDCE9C4, 0x26360A), blob2: (0xE7F0D6, 0x18230A),
                promptLight: (0xE2EFCB, 0xC9DFA2), video: (0x4D6B1A, 0x2B3D0E),
                widgetTop: (0xFFFFFF, 0x1A2408), widgetBottom: (0xEAF2DC, 0x0C1104)),
        Palette(id: "grape", name: "Grape",
                accent: (0x7C3AED, 0xA78BFA), accentInk: (0xFFFFFF, 0x12062B), accentText: (0x6025C9, 0xC4B5FD),
                softLight: 0xEDE5FD, bg: (0xF3F0FB, 0x0D0820), blob1: (0xDDD0F8, 0x2E1660), blob2: (0xE8E0FA, 0x1C0F40),
                promptLight: (0xE8DEFC, 0xD2C0F8), video: (0x5B3AA8, 0x34206A),
                widgetTop: (0xFFFFFF, 0x1E1242), widgetBottom: (0xEEE7FC, 0x100A26)),
        Palette(id: "mint", name: "Mint",
                accent: (0x0B8F63, 0x34D399), accentInk: (0xFFFFFF, 0x02200F), accentText: (0x0A7350, 0x7EE8BC),
                softLight: 0xDDF5EB, bg: (0xEDF7F3, 0x04140E), blob1: (0xC8EBDD, 0x0C3B29), blob2: (0xDAF1E7, 0x08281C),
                promptLight: (0xD6F2E6, 0xB2E3CE), video: (0x1A7A58, 0x0E4A35),
                widgetTop: (0xFFFFFF, 0x0A2A1E), widgetBottom: (0xE2F4EC, 0x051710)),
        Palette(id: "rose", name: "Rose",
                accent: (0xD3203F, 0xFF6B85), accentInk: (0xFFFFFF, 0x2A0510), accentText: (0xAD1B37, 0xFFA3B3),
                softLight: 0xFCE3E8, bg: (0xFAF0F2, 0x16070B), blob1: (0xF6D3DA, 0x4A1220), blob2: (0xF9E2E7, 0x2E0B14),
                promptLight: (0xFBDDE3, 0xF4BAC6), video: (0xA3263F, 0x661828),
                widgetTop: (0xFFFFFF, 0x2C0C15), widgetBottom: (0xFBE6EA, 0x18060B)),
        Palette(id: "mono", name: "Mono",
                accent: (0x1D1D1F, 0xF2F2F5), accentInk: (0xFFFFFF, 0x000000), accentText: (0x1D1D1F, 0xE5E5EA),
                softLight: 0xE8E8ED, bg: (0xF2F2F4, 0x0A0A0B), blob1: (0xE2E2E7, 0x242426), blob2: (0xEAEAEE, 0x1A1A1C),
                promptLight: (0xE6E6EB, 0xD1D1D6), video: (0x3A3A3C, 0x2C2C2E),
                widgetTop: (0xFFFFFF, 0x1C1C1E), widgetBottom: (0xEDEDF0, 0x0B0B0C)),
    ]

    static let glacier = all[0]

    static func named(_ id: String?) -> Palette {
        all.first { $0.id == id } ?? glacier
    }

    /// The palette saved in the App Group (what widgets use).
    static var stored: Palette { named(SharedStore.defaults.string(forKey: defaultsKey)) }

    /// The app's live palette. Set by the Store whenever the setting changes.
    static var current: Palette = glacier

    // MARK: Colors

    static func color(_ light: UInt32, _ dark: UInt32, la: CGFloat = 1, da: CGFloat = 1) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(paletteHex: dark, alpha: da) : UIColor(paletteHex: light, alpha: la)
        })
    }

    var accentColor: Color { Palette.color(accent.0, accent.1) }
    var accentInkColor: Color { Palette.color(accentInk.0, accentInk.1) }
    var accentTextColor: Color { Palette.color(accentText.0, accentText.1) }
    var accentSoftColor: Color { Palette.color(softLight, accent.1, da: 0.17) }
    var bgColor: Color { Palette.color(bg.0, bg.1) }
    var blob1Color: Color { Palette.color(blob1.0, blob1.1) }
    var blob2Color: Color { Palette.color(blob2.0, blob2.1) }
    var promptBgColor: Color { Palette.color(promptLight.bg, accent.1, da: 0.14) }
    var promptBorderColor: Color { Palette.color(promptLight.border, accent.1, da: 0.35) }
    var videoColor: Color { Palette.color(video.0, video.1) }
    var widgetTopColor: Color { Palette.color(widgetTop.0, widgetTop.1) }
    var widgetBottomColor: Color { Palette.color(widgetBottom.0, widgetBottom.1) }

    /// Deep version of the accent for the lock screen rest timer background.
    var deepColor: Color {
        let h = accent.0
        let f = 0.55
        return Color(red: Double((h >> 16) & 0xFF) / 255 * f, green: Double((h >> 8) & 0xFF) / 255 * f, blue: Double(h & 0xFF) / 255 * f)
    }

    /// Swatch for pickers: light accent on the left, dark on the right.
    var swatchLight: Color { Color(UIColor(paletteHex: accent.0)) }
    var swatchDark: Color { Color(UIColor(paletteHex: accent.1)) }
}

extension UIColor {
    convenience init(paletteHex hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
