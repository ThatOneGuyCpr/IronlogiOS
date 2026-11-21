import SwiftUI
import UIKit

// Whole-app themes. Glacier is the original look and keeps the color, background and
// number settings. Every other skin brings its own type, colors, shapes and a few words.
// Shared by the app, the widgets and the Live Activity.

/// A typeface: bundled faces by weight, or the system font.
struct FontFace {
    /// (weight 100-900, PostScript name). Empty means the system font.
    var faces: [(Int, String)] = []
    var scale: CGFloat = 1
    var design: Font.Design = .default
    /// For the system font: always use this weight.
    var fixedWeight: Font.Weight? = nil

    static func system(_ design: Font.Design = .default, weight: Font.Weight? = nil) -> FontFace {
        FontFace(faces: [], scale: 1, design: design, fixedWeight: weight)
    }

    static func custom(_ faces: [(Int, String)], scale: CGFloat = 1) -> FontFace {
        FontFace(faces: faces, scale: scale)
    }

    static func number(_ w: Font.Weight) -> Int {
        if w == .ultraLight { return 100 }
        if w == .thin { return 200 }
        if w == .light { return 300 }
        if w == .medium { return 500 }
        if w == .semibold { return 600 }
        if w == .bold { return 700 }
        if w == .heavy { return 800 }
        if w == .black { return 900 }
        return 400
    }

    static func uiWeight(_ w: Font.Weight) -> UIFont.Weight {
        switch number(w) {
        case 100: return .ultraLight
        case 200: return .thin
        case 300: return .light
        case 500: return .medium
        case 600: return .semibold
        case 700: return .bold
        case 800: return .heavy
        case 900: return .black
        default: return .regular
        }
    }

    func name(for weight: Font.Weight) -> String? {
        guard !faces.isEmpty else { return nil }
        let w = FontFace.number(weight)
        var best = faces[0]
        for f in faces where abs(f.0 - w) < abs(best.0 - w) { best = f }
        return best.1
    }

    func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if let n = name(for: weight) { return .custom(n, fixedSize: size * scale) }
        return .system(size: size, weight: fixedWeight ?? weight, design: design)
    }

    func uiFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> UIFont {
        if let n = name(for: weight), let f = UIFont(name: n, size: size * scale) { return f }
        return .systemFont(ofSize: size, weight: FontFace.uiWeight(fixedWeight ?? weight))
    }
}

/// A color with alpha, fixed for the skin's light or dark scheme.
struct Hue {
    let hex: UInt32
    var alpha: CGFloat = 1

    var color: Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255, opacity: Double(alpha))
    }

    var uiColor: UIColor { UIColor(paletteHex: hex, alpha: alpha) }
}

private func h(_ hex: UInt32, _ a: CGFloat = 1) -> Hue { Hue(hex: hex, alpha: a) }

struct SkinColors {
    var bg: Hue
    var bg2: Hue
    var card: Hue
    var cardBorder: Hue
    var ink: Hue
    var sub: Hue
    var faint: Hue
    var chip: Hue
    var field: Hue
    var fieldBorder: Hue
    /// Text drawn straight on the background (headers, titles).
    var head: Hue
    var headSub: Hue
    var accent: Hue
    var accentInk: Hue
    var accentText: Hue
    var accentSoft: Hue
    /// Done days in the week strip.
    var done: Hue
    var doneInk: Hue
    var good: Hue
    var warn: Hue
    /// Settings rows.
    var row: Hue
    var tabBg: Hue
    var widgetTop: Hue
    var widgetBottom: Hue
    var widgetInk: Hue
    var widgetSub: Hue
    var widgetAccent: Hue
    var widgetAccentInk: Hue
    var widgetFaint: Hue
    /// Lock screen timer background.
    var deep: Hue
}

enum CardLook { case glacier, pixel, rule, terminal, swiss, aero, window, panel, broadcast, vice }
enum Backdrop { case glacier, dots, paper, scanlines, plain, aurora, dither, rays, stripes, sunset }
enum ButtonLook { case glacier, block, ink, prompt, swiss, gel, mac, bell, skew, vice }
enum TabLook { case system, block, text, taskbar, window, ropes, underline, pause }
enum DotLook { case circle, gloss, square, checkbox, skew, blip, text, score }
enum HeroLook { case standard, mainEvent, lowerThird, mission }
enum HeaderLook { case standard, masthead, prompt, hud, menubar, bug }

struct SkinWords {
    var train = "Train"
    var upNext = "UP NEXT"
    var picked = "PICKED"
    var start = "Start workout"
    var thisWeek = "This week"
    var lineup = "Today's lineup"
    var tabs = ["Train", "Progress", "History", "Settings"]
    var finish = "Workout saved"
    var finishSub: String? = nil
}

struct Skin: Identifiable {
    let id: String
    let name: String
    let blurb: String
    /// Forced light or dark. nil follows the Appearance setting (Glacier only).
    let scheme: ColorScheme?
    let colors: SkinColors?
    var display: FontFace = .system()
    var body: FontFace = .system()
    var label: FontFace = .system()
    var number: FontFace = .system()
    /// Uppercase all text.
    var allCaps = false
    /// Uppercase big titles.
    var titleCaps = false
    var card: CardLook = .glacier
    var backdrop: Backdrop = .glacier
    var button: ButtonLook = .glacier
    var tab: TabLook = .system
    var dot: DotLook = .circle
    var hero: HeroLook = .standard
    var header: HeaderLook = .standard
    var cardRadius: CGFloat = 24
    var heroSize: CGFloat = 32
    var words = SkinWords()
    /// App icon that goes with it.
    var icon: String? = nil

    var isGlacier: Bool { id == "glacier" }

    /// Picks display, label or body type from size and weight, so plain sizes theme themselves.
    func face(size: CGFloat, weight: Font.Weight) -> FontFace {
        let w = FontFace.number(weight)
        if size >= 22 && w >= 600 { return display }
        if size <= 12 && w >= 600 { return label }
        return body
    }

    func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        if isGlacier { return .system(size: size, weight: weight, design: design) }
        return face(size: size, weight: weight).font(size, weight)
    }

    // MARK: Store

    static let defaultsKey = "skin"
    static let colorKey = "skinColor"

    /// The app's live skin. Set by the Store.
    static var current: Skin = glacier
    /// A palette picked to replace the skin's own accent.
    static var accentOverride: Palette?

    static func named(_ id: String?) -> Skin { all.first { $0.id == id } ?? glacier }

    /// What the widgets use.
    static var stored: Skin { named(SharedStore.defaults.string(forKey: defaultsKey)) }
    static var storedOverride: Palette? {
        let id = SharedStore.defaults.string(forKey: colorKey)
        return (id == nil || id == "theme") ? nil : Palette.named(id)
    }

    /// Accent with any override applied.
    func accent(override: Palette?) -> (accent: Color, ink: Color, text: Color, soft: Color)? {
        guard let c = colors else { return nil }
        if let p = override {
            let dark = scheme == .dark
            let a = Hue(hex: dark ? p.accent.1 : p.accent.0)
            let ink = Hue(hex: dark ? p.accentInk.1 : p.accentInk.0)
            let text = Hue(hex: dark ? p.accentText.1 : p.accentText.0)
            return (a.color, ink.color, text.color, Hue(hex: a.hex, alpha: dark ? 0.18 : 0.12).color)
        }
        return (c.accent.color, c.accentInk.color, c.accentText.color, c.accentSoft.color)
    }

    // MARK: Faces

    private static let pressStart = FontFace.custom([(400, "IL-PressStart2P-400")], scale: 0.64)
    private static let vt323 = FontFace.custom([(400, "IL-VT323-400")], scale: 1.32)
    private static let playfair = FontFace.custom([(700, "IL-Playfair-700"), (900, "IL-Playfair-900")])
    private static let sourceSerif = FontFace.custom([(400, "IL-SourceSerif-400"), (600, "IL-SourceSerif-600")])
    private static let franklin = FontFace.custom([(500, "IL-Franklin-500"), (700, "IL-Franklin-700"), (800, "IL-Franklin-800")])
    private static let mono = FontFace.custom([(400, "IL-JBMono-400"), (700, "IL-JBMono-700"), (800, "IL-JBMono-800")], scale: 0.94)
    private static let archivoBlack = FontFace.custom([(400, "IL-ArchivoBlack-400")])
    private static let archivo = FontFace.custom([(400, "IL-Archivo-400"), (500, "IL-Archivo-500"), (700, "IL-Archivo-700")])
    private static let pixelify = FontFace.custom([(400, "IL-Pixelify-400"), (500, "IL-Pixelify-500"), (600, "IL-Pixelify-600"), (700, "IL-Pixelify-700")])
    private static let silkscreen = FontFace.custom([(400, "IL-Silkscreen-400")], scale: 0.92)
    private static let anton = FontFace.custom([(400, "IL-Anton-400")], scale: 1.04)
    private static let oswald = FontFace.custom([(500, "IL-Oswald-500"), (600, "IL-Oswald-600"), (700, "IL-Oswald-700")])
    private static let barlow = FontFace.custom([(500, "IL-BarlowCond-500"), (600, "IL-BarlowCond-600"), (700, "IL-BarlowCond-700"), (800, "IL-BarlowCond-800")], scale: 1.12)
    private static let barlowItalic = FontFace.custom([(700, "IL-BarlowCond-700i"), (800, "IL-BarlowCond-800i")], scale: 1.12)
    private static let passion = FontFace.custom([(400, "IL-PassionOne-400"), (700, "IL-PassionOne-700")], scale: 1.12)
    private static let rubik = FontFace.custom([(400, "IL-Rubik-400"), (500, "IL-Rubik-500"), (600, "IL-Rubik-600"), (700, "IL-Rubik-700")])

    static let blackletter = FontFace.custom([(400, "IL-Unifraktur-400")])
    static let script = FontFace.custom([(400, "IL-Yellowtail-400")])

    // MARK: The skins

    static let glacier = Skin(id: "glacier", name: "Glacier", blurb: "Glass and blue", scheme: nil, colors: nil)

    static let eightBit = Skin(
        id: "8bit", name: "8-Bit", blurb: "Console RPG", scheme: .dark,
        colors: SkinColors(
            bg: h(0x12143A), bg2: h(0x12143A), card: h(0x23285C), cardBorder: h(0xFFFFFF),
            ink: h(0xFFFFFF), sub: h(0xA8B0E8), faint: h(0x3A3F75), chip: h(0x2B3170),
            field: h(0x1B1F4D), fieldBorder: h(0x5B63B8), head: h(0xFFFFFF), headSub: h(0xA8B0E8),
            accent: h(0xFFD23F), accentInk: h(0x12143A), accentText: h(0xFFD23F), accentSoft: h(0xFFD23F, 0.18),
            done: h(0x4DA3FF), doneInk: h(0x12143A), good: h(0x7CF29C), warn: h(0xFF4D6D),
            row: h(0x23285C), tabBg: h(0x0B0C24),
            widgetTop: h(0x23285C), widgetBottom: h(0x12143A), widgetInk: h(0xFFFFFF), widgetSub: h(0xA8B0E8),
            widgetAccent: h(0xFFD23F), widgetAccentInk: h(0x12143A), widgetFaint: h(0x3A3F75), deep: h(0x12143A)),
        display: pressStart, body: vt323, label: pressStart, number: FontFace.custom([(400, "IL-PressStart2P-400")], scale: 0.72),
        allCaps: true, card: .pixel, backdrop: .dots, button: .block, tab: .block, dot: .square,
        cardRadius: 0, heroSize: 30,
        words: SkinWords(train: "TRAIN", upNext: "NEXT QUEST", picked: "PICKED", start: "▶ START", thisWeek: "THIS WEEK",
                         lineup: "MOVES", tabs: ["TRAIN", "STATS", "LOG", "MENU"], finish: "QUEST COMPLETE"),
        icon: "cartridge")

    static let broadsheet = Skin(
        id: "broadsheet", name: "Broadsheet", blurb: "Newspaper", scheme: .light,
        colors: SkinColors(
            bg: h(0xF4EFE4), bg2: h(0xF4EFE4), card: h(0xF4EFE4, 0), cardBorder: h(0x1A1712),
            ink: h(0x1A1712), sub: h(0x5E574A), faint: h(0xD9D0BD), chip: h(0xEAE3D3),
            field: h(0xEDE6D6), fieldBorder: h(0xBDB29A), head: h(0x1A1712), headSub: h(0x5E574A),
            accent: h(0x1A1712), accentInk: h(0xF4EFE4), accentText: h(0xA3201B), accentSoft: h(0xA3201B, 0.10),
            done: h(0x1A1712), doneInk: h(0xF4EFE4), good: h(0x2E6B2E), warn: h(0xA3201B),
            row: h(0xFBF8F1), tabBg: h(0xF4EFE4),
            widgetTop: h(0xF8F4EA), widgetBottom: h(0xEFE8D8), widgetInk: h(0x1A1712), widgetSub: h(0x5E574A),
            widgetAccent: h(0xA3201B), widgetAccentInk: h(0xFFFFFF), widgetFaint: h(0xD9D0BD), deep: h(0x2A2620)),
        display: playfair, body: sourceSerif, label: franklin, number: playfair,
        card: .rule, backdrop: .paper, button: .ink, tab: .text, dot: .text, header: .masthead,
        cardRadius: 0, heroSize: 34,
        words: SkinWords(train: "Train", upNext: "TODAY'S WORKOUT", picked: "YOUR PICK", start: "Begin workout",
                         thisWeek: "The week in brief", lineup: "In this session",
                         tabs: ["Train", "Progress", "Archive", "Settings"], finish: "Filed."),
        icon: "press")

    static let terminal = Skin(
        id: "terminal", name: "Terminal", blurb: "Dev tools, dark", scheme: .dark,
        colors: SkinColors(
            bg: h(0x0B0F0C), bg2: h(0x0B0F0C), card: h(0x0E1410), cardBorder: h(0x24402E),
            ink: h(0xC7F9D5), sub: h(0x8FB79A), faint: h(0x24402E), chip: h(0x13201A),
            field: h(0x101812), fieldBorder: h(0x2E5A3E), head: h(0xC7F9D5), headSub: h(0x4D6B57),
            accent: h(0x7CF2A0), accentInk: h(0x0B0F0C), accentText: h(0x7CF2A0), accentSoft: h(0x7CF2A0, 0.10),
            done: h(0x7CF2A0), doneInk: h(0x0B0F0C), good: h(0x7CF2A0), warn: h(0xFF6B6B),
            row: h(0x0E1410), tabBg: h(0x0E1410),
            widgetTop: h(0x0E1410), widgetBottom: h(0x0B0F0C), widgetInk: h(0xC7F9D5), widgetSub: h(0x8FB79A),
            widgetAccent: h(0x7CF2A0), widgetAccentInk: h(0x0B0F0C), widgetFaint: h(0x24402E), deep: h(0x0B1A10)),
        display: mono, body: mono, label: mono, number: mono,
        card: .terminal, backdrop: .scanlines, button: .prompt, tab: .block, dot: .text, header: .prompt,
        cardRadius: 2, heroSize: 28,
        words: SkinWords(train: "train", upNext: "$ next", picked: "$ picked", start: "start", thisWeek: "$ week",
                         lineup: "$ ls", tabs: ["train", "stats", "log", "config"], finish: "exit 0 · saved"),
        icon: "prompt")

    static let swiss = Skin(
        id: "swiss", name: "Swiss", blurb: "Poster grid", scheme: .light,
        colors: SkinColors(
            bg: h(0xF7F7F7), bg2: h(0xF7F7F7), card: h(0xF7F7F7, 0), cardBorder: h(0x0D0D0D),
            ink: h(0x0D0D0D), sub: h(0x6B6B6B), faint: h(0xE2E2E2), chip: h(0xEAEAEA),
            field: h(0xEEEEEE), fieldBorder: h(0xC8C8C8), head: h(0x0D0D0D), headSub: h(0x6B6B6B),
            accent: h(0xDA1F00), accentInk: h(0xF7F7F7), accentText: h(0xDA1F00), accentSoft: h(0xDA1F00, 0.08),
            done: h(0x0D0D0D), doneInk: h(0xF7F7F7), good: h(0x1E7B34), warn: h(0xDA1F00),
            row: h(0xFFFFFF), tabBg: h(0xF7F7F7),
            widgetTop: h(0xFFFFFF), widgetBottom: h(0xF0F0F0), widgetInk: h(0x0D0D0D), widgetSub: h(0x6B6B6B),
            widgetAccent: h(0xDA1F00), widgetAccentInk: h(0xFFFFFF), widgetFaint: h(0xE2E2E2), deep: h(0x6E1000)),
        display: archivoBlack, body: archivo, label: archivo, number: archivoBlack,
        titleCaps: true, card: .swiss, backdrop: .plain, button: .swiss, tab: .text, dot: .square,
        cardRadius: 0, heroSize: 64,
        words: SkinWords(train: "TRAIN", upNext: "NEXT", picked: "PICKED", start: "START →", thisWeek: "WEEK",
                         lineup: "LINEUP", tabs: ["TRAIN", "PROGRESS", "HISTORY", "SETTINGS"], finish: "DONE."),
        icon: "poster")

    static let aero = Skin(
        id: "aero", name: "Aero", blurb: "Windows glass", scheme: .light,
        colors: SkinColors(
            bg: h(0x0B4C86), bg2: h(0x1C8FC9), card: h(0xFFFFFF), cardBorder: h(0x2C4E6E),
            ink: h(0x1A2B3C), sub: h(0x4F5B66), faint: h(0xD5DEE8), chip: h(0xEEF4FA),
            field: h(0xF3F7FB), fieldBorder: h(0x9FB6CC), head: h(0xFFFFFF), headSub: h(0xE0F0FF),
            accent: h(0x2B8AE0), accentInk: h(0xFFFFFF), accentText: h(0x1E5FAF), accentSoft: h(0x2B8AE0, 0.12),
            done: h(0x37AE1F), doneInk: h(0xFFFFFF), good: h(0x2E9A1C), warn: h(0xC3301C),
            row: h(0xFFFFFF, 0.92), tabBg: h(0x0A1E37, 0.85),
            widgetTop: h(0x1678B8), widgetBottom: h(0x0B4C86), widgetInk: h(0xFFFFFF), widgetSub: h(0xD8ECFF),
            widgetAccent: h(0x9CF27A), widgetAccentInk: h(0x0B3A1A), widgetFaint: h(0xFFFFFF, 0.22), deep: h(0x0B3A66)),
        display: .system(weight: .regular), body: .system(), label: .system(), number: .system(weight: .semibold),
        card: .aero, backdrop: .aurora, button: .gel, tab: .taskbar, dot: .gloss,
        cardRadius: 9, heroSize: 28,
        words: SkinWords(upNext: "Up next"),
        icon: "aero")

    static let oneBit = Skin(
        id: "onebit", name: "1-Bit", blurb: "Classic Mac", scheme: .light,
        colors: SkinColors(
            bg: h(0xFFFFFF), bg2: h(0xFFFFFF), card: h(0xFFFFFF), cardBorder: h(0x000000),
            ink: h(0x000000), sub: h(0x4A4A4A), faint: h(0xBDBDBD), chip: h(0xFFFFFF),
            field: h(0xFFFFFF), fieldBorder: h(0x000000), head: h(0x000000), headSub: h(0x000000),
            accent: h(0x000000), accentInk: h(0xFFFFFF), accentText: h(0x000000), accentSoft: h(0x000000, 0.08),
            done: h(0x000000), doneInk: h(0xFFFFFF), good: h(0x000000), warn: h(0x000000),
            row: h(0xFFFFFF), tabBg: h(0xFFFFFF),
            widgetTop: h(0xFFFFFF), widgetBottom: h(0xFFFFFF), widgetInk: h(0x000000), widgetSub: h(0x4A4A4A),
            widgetAccent: h(0x000000), widgetAccentInk: h(0xFFFFFF), widgetFaint: h(0xBDBDBD), deep: h(0x000000)),
        display: pixelify, body: pixelify, label: silkscreen, number: FontFace.custom([(700, "IL-Pixelify-700")]),
        card: .window, backdrop: .dither, button: .mac, tab: .window, dot: .checkbox, header: .menubar,
        cardRadius: 0, heroSize: 30,
        words: SkinWords(upNext: "Up Next", finish: "Workout saved."),
        icon: "onebit")

    static let mainEvent = Skin(
        id: "mainevent", name: "Main Event", blurb: "80s wrestling", scheme: .dark,
        colors: SkinColors(
            bg: h(0x1E2C78), bg2: h(0x06081C), card: h(0x0A0E2A, 0.85), cardBorder: h(0x33417F),
            ink: h(0xFFFFFF), sub: h(0xB8C3F0), faint: h(0x222C63), chip: h(0x151C4A),
            field: h(0x10163D), fieldBorder: h(0x33417F), head: h(0xFFFFFF), headSub: h(0xFFD447),
            accent: h(0xD7263D), accentInk: h(0xFFFFFF), accentText: h(0xFFD447), accentSoft: h(0xFFD447, 0.15),
            done: h(0xFFD447), doneInk: h(0x0B1030), good: h(0xFFD447), warn: h(0xFF4258),
            row: h(0x0E1338), tabBg: h(0x06081C),
            widgetTop: h(0x1E2C78), widgetBottom: h(0x06081C), widgetInk: h(0xFFFFFF), widgetSub: h(0xB8C3F0),
            widgetAccent: h(0xFFD447), widgetAccentInk: h(0x0B1030), widgetFaint: h(0x33417F), deep: h(0x3A0A14)),
        display: anton, body: oswald, label: oswald, number: anton,
        allCaps: true, card: .panel, backdrop: .rays, button: .bell, tab: .ropes, dot: .skew, hero: .mainEvent,
        cardRadius: 0, heroSize: 84,
        words: SkinWords(train: "TONIGHT", upNext: "TONIGHT'S MAIN EVENT", picked: "CARD CHANGE", start: "RING THE BELL",
                         thisWeek: "THIS WEEK'S CARD", lineup: "MATCH ORDER",
                         tabs: ["TONIGHT", "STATS", "RECORD", "LOCKER"], finish: "AND STILL CHAMPION"),
        icon: "mainevent")

    static let broadcast = Skin(
        id: "broadcast", name: "Broadcast", blurb: "TV sports graphics", scheme: .dark,
        colors: SkinColors(
            bg: h(0x13204A), bg2: h(0x060A1A), card: h(0x111B3D), cardBorder: h(0x1C2A5C),
            ink: h(0xFFFFFF), sub: h(0x8E9AC4), faint: h(0x1C2A5C), chip: h(0x1C2A5C),
            field: h(0x0E1734), fieldBorder: h(0x2B3A70), head: h(0xFFFFFF), headSub: h(0x8E9AC4),
            accent: h(0xE4002B), accentInk: h(0xFFFFFF), accentText: h(0xFFC72C), accentSoft: h(0xFFC72C, 0.15),
            done: h(0xFFFFFF), doneInk: h(0x0A1128), good: h(0x3DDC84), warn: h(0xE4002B),
            row: h(0x111B3D), tabBg: h(0x060A1A),
            widgetTop: h(0x13204A), widgetBottom: h(0x0A1128), widgetInk: h(0xFFFFFF), widgetSub: h(0x8E9AC4),
            widgetAccent: h(0xFFC72C), widgetAccentInk: h(0x0A1128), widgetFaint: h(0x2B3A70), deep: h(0x0A1128)),
        display: barlowItalic, body: barlow, label: barlow, number: barlow,
        allCaps: true, card: .broadcast, backdrop: .stripes, button: .skew, tab: .underline, dot: .score,
        hero: .lowerThird, header: .bug, cardRadius: 0, heroSize: 58,
        words: SkinWords(train: "TRAIN", upNext: "UP NEXT", picked: "LINEUP CHANGE", start: "START WORKOUT ▶",
                         thisWeek: "THIS WEEK", lineup: "STARTING LINEUP",
                         tabs: ["TRAIN", "STATS", "HISTORY", "SETTINGS"], finish: "FINAL"))

    static let vice = Skin(
        id: "vice", name: "Vice City", blurb: "Sunset missions", scheme: .dark,
        colors: SkinColors(
            bg: h(0x1A0A2E), bg2: h(0x0B0412), card: h(0x0B0412, 0.72), cardBorder: h(0xFFFFFF, 0.12),
            ink: h(0xFFFFFF), sub: h(0xC9B6DA), faint: h(0xFFFFFF, 0.12), chip: h(0x24103A),
            field: h(0x1A0A2E), fieldBorder: h(0x4A2A66), head: h(0xFFFFFF), headSub: h(0xE8DDF2),
            accent: h(0xFF4F9A), accentInk: h(0xFFFFFF), accentText: h(0xF0C850), accentSoft: h(0xFF4F9A, 0.16),
            done: h(0xFF4F9A), doneInk: h(0xFFFFFF), good: h(0x7EE08A), warn: h(0xFF4F6B),
            row: h(0x1A0A2E), tabBg: h(0x0B0412),
            widgetTop: h(0x6A1B6E), widgetBottom: h(0x1A0A2E), widgetInk: h(0xFFFFFF), widgetSub: h(0xE8DDF2),
            widgetAccent: h(0xFF4F9A), widgetAccentInk: h(0xFFFFFF), widgetFaint: h(0xFFFFFF, 0.18), deep: h(0x4A0E3E)),
        display: passion, body: rubik, label: FontFace.custom([(400, "IL-PassionOne-400")], scale: 1.22), number: passion,
        titleCaps: true, card: .vice, backdrop: .sunset, button: .vice, tab: .pause, dot: .blip, hero: .mission,
        header: .hud, cardRadius: 0, heroSize: 58,
        words: SkinWords(train: "Train", upNext: "MISSION", picked: "SIDE MISSION", start: "START MISSION",
                         thisWeek: "THIS WEEK", lineup: "OBJECTIVES", tabs: ["TRAIN", "STATS", "BRIEF", "SETTINGS"],
                         finish: "MISSION PASSED", finishSub: "RESPECT +"),
        icon: "vice")

    static let all: [Skin] = [glacier, eightBit, broadsheet, terminal, swiss, aero, oneBit, mainEvent, broadcast, vice]
}
