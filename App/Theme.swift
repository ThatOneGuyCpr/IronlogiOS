import SwiftUI
import UIKit

// MARK: - Colors

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

/// Everything views draw with. Glacier uses the palette and look settings; other skins bring their own.
enum Theme {
    static var skin: Skin { Skin.current }
    private static var sc: SkinColors? { skin.colors }
    private static var skinAccent: (accent: Color, ink: Color, text: Color, soft: Color)? {
        skin.accent(override: Skin.accentOverride)
    }

    static var palette: Palette { Palette.current }
    static var bg: Color {
        if let c = sc { return c.bg.color }
        return backgroundStyle == .black ? Color.dyn(Palette.current.bg.0, 0x000000) : palette.bgColor
    }
    static var blob1: Color { palette.blob1Color }
    static var blob2: Color { palette.blob2Color }
    static var accent: Color { skinAccent?.accent ?? palette.accentColor }
    static var accentInk: Color { skinAccent?.ink ?? palette.accentInkColor }
    static var accentSoft: Color { skinAccent?.soft ?? palette.accentSoftColor }
    static var accentText: Color { skinAccent?.text ?? palette.accentTextColor }
    static var promptBg: Color { sc != nil ? accentSoft : palette.promptBgColor }
    static var promptBorder: Color { sc != nil ? accent.opacity(0.45) : palette.promptBorderColor }
    static var video: Color { sc?.field.color ?? palette.videoColor }

    static var card: Color { sc?.card.color ?? Color.dyn(0xFFFFFF, 0xFFFFFF, la: 0.82, da: 0.065) }
    static var cardBorder: Color { sc?.cardBorder.color ?? Color.dyn(0xFFFFFF, 0xFFFFFF, la: 0.95, da: 0.11) }
    static var ink: Color { sc?.ink.color ?? Color.dyn(0x0B1B2E, 0xF2F6FB) }
    static var sub: Color { sc?.sub.color ?? Color.dyn(0x4A5D73, 0xA9B8CA) }
    static var faint: Color { sc?.faint.color ?? Color.dyn(0xE4ECF5, 0xFFFFFF, da: 0.08) }
    static var chip: Color { sc?.chip.color ?? Color.dyn(0xEEF3F9, 0xFFFFFF, da: 0.08) }
    static var field: Color { sc?.field.color ?? Color.dyn(0xF4F8FC, 0xFFFFFF, da: 0.07) }
    static var fieldBorder: Color { sc?.fieldBorder.color ?? Color.dyn(0xCCDAEA, 0xFFFFFF, da: 0.16) }
    static var good: Color { sc?.good.color ?? Color.dyn(0x15803D, 0x34C759) }
    static var goodInk: Color { sc.map { skin.scheme == .dark ? $0.bg2.color : Color.white } ?? Color.dyn(0xFFFFFF, 0x05210E) }
    static var goodRow: Color { sc.map { $0.good.color.opacity(0.12) } ?? Color.dyn(0xEAF7EF, 0x34C759, da: 0.10) }
    static var goodText: Color { sc?.good.color ?? Color.dyn(0x15803D, 0x5BD68A) }
    static var warn: Color { sc?.warn.color ?? Color.dyn(0xB42318, 0xFF8A80) }
    static var shadow: Color { sc != nil ? Color.black.opacity(skin.card == .aero ? 0.4 : 0) : Color.dyn(0x102A4D, 0x000000, la: 0.08, da: 0.35) }

    /// Text drawn straight on the background.
    static var head: Color { sc?.head.color ?? ink }
    static var headSub: Color { sc?.headSub.color ?? sub }
    static var done: Color { sc?.done.color ?? accent }
    static var doneInk: Color { sc?.doneInk.color ?? accentInk }
    static var row: Color? { sc?.row.color }
    static var tabBg: Color { sc?.tabBg.color ?? bg }
    static var words: SkinWords { skin.words }

    // Kept so older call sites still compile.
    static var sky: Color { accent }

    // Look settings, set by the Store. Glacier only.
    static var backgroundStyle: BackgroundStyle = .sky
    static var numberStyle: NumberStyle = .standard

    /// Text font. Other skins pick display, label or body type from the size and weight.
    static func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        skin.font(size: size, weight: weight, design: design)
    }

    /// Big titles.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        skin.isGlacier ? .system(size: size, weight: weight) : skin.display.font(size, weight)
    }

    /// Small headings and kickers.
    static func label(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        skin.isGlacier ? .system(size: size, weight: weight) : skin.label.font(size, weight)
    }

    /// Font for big numbers (weights, timers, stats), following the Numbers setting on Glacier.
    static func num(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        if !skin.isGlacier { return skin.number.font(size, weight).monospacedDigit() }
        switch numberStyle {
        case .standard:
            return Font.system(size: size, weight: weight).monospacedDigit()
        case .rounded:
            return Font.system(size: size, weight: weight, design: .rounded).monospacedDigit()
        case .condensed:
            return Font.system(size: size * 1.12, weight: weight == .heavy ? .black : weight).width(.condensed).monospacedDigit()
        }
    }

    /// System text styles, themed. Sizes match the default Dynamic Type size.
    static func style(_ style: Font.TextStyle, _ weight: Font.Weight? = nil) -> Font {
        if skin.isGlacier {
            let f = Font.system(style)
            return weight.map { f.weight($0) } ?? f
        }
        let spec: (CGFloat, Font.Weight) = {
            switch style {
            case .largeTitle: return (34, .bold)
            case .title: return (28, .bold)
            case .title2: return (22, .bold)
            case .title3: return (20, .semibold)
            case .headline: return (17, .semibold)
            case .callout: return (16, .regular)
            case .subheadline: return (15, .regular)
            case .footnote: return (13, .regular)
            case .caption: return (12, .regular)
            case .caption2: return (11, .regular)
            default: return (17, .regular)
            }
        }()
        return font(size: spec.0, weight: weight ?? spec.1)
    }

    /// Room the themed tab bar takes at the bottom of the screen.
    static var tabBarHeight: CGFloat {
        switch skin.tab {
        case .system: return 0
        case .block: return 62
        case .text: return 54
        case .taskbar: return 58
        case .window: return 67
        case .ropes: return 61
        case .underline: return 52
        case .pause: return 62
        }
    }

    static var squareCorners: Bool { !skin.isGlacier && skin.cardRadius <= 2 }
    static func radius(_ glacier: CGFloat) -> CGFloat {
        skin.isGlacier ? glacier : min(glacier, skin.cardRadius)
    }
}

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case sky, plain, black
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sky: return "Sky"
        case .plain: return "Plain"
        case .black: return "True black"
        }
    }
}

enum NumberStyle: String, CaseIterable, Identifiable {
    case standard, rounded, condensed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: return "Standard"
        case .rounded: return "Rounded"
        case .condensed: return "Condensed"
        }
    }
}

// MARK: - Background

struct SkyBackground: View {
    /// Lists and forms: swap a busy pattern for a plain fill so headers and footers stay readable.
    var calm = false

    var body: some View {
        backdrop.ignoresSafeArea()
    }

    @ViewBuilder
    private var backdrop: some View {
        if calm && Theme.skin.backdrop == .dither {
            Color.white
        } else {
            pattern
        }
    }

    @ViewBuilder
    private var pattern: some View {
        switch Theme.skin.backdrop {
        case .glacier:
            ZStack {
                Theme.bg
                if Theme.backgroundStyle == .sky { blobs }
            }
        case .paper, .plain:
            Theme.bg
        case .dots:
            Theme.bg.overlay {
                Canvas { ctx, size in
                    let c = Color(red: 0x3A / 255, green: 0x3F / 255, blue: 0x75 / 255).opacity(0.7)
                    var y: CGFloat = 11
                    while y < size.height {
                        var x: CGFloat = 11
                        while x < size.width {
                            ctx.fill(Path(CGRect(x: x, y: y, width: 2, height: 2)), with: .color(c))
                            x += 22
                        }
                        y += 22
                    }
                }
            }
        case .scanlines:
            Theme.bg.overlay {
                Canvas { ctx, size in
                    var y: CGFloat = 0
                    while y < size.height {
                        ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Theme.accent.opacity(0.035)))
                        y += 3
                    }
                }
            }
        case .aurora:
            Image("AeroWallpaper")
                .resizable()
                .scaledToFill()
        case .dither:
            Image(uiImage: DitherTile.image)
                .resizable(resizingMode: .tile)
                .interpolation(.none)
        case .rays:
            ZStack {
                RadialGradient(colors: [Color(red: 0.12, green: 0.17, blue: 0.47), Color(red: 0.04, green: 0.06, blue: 0.19), Color(red: 0.02, green: 0.03, blue: 0.11)],
                               center: UnitPoint(x: 0.5, y: 0.22), startRadius: 0, endRadius: 620)
                Canvas { ctx, size in
                    let o = CGPoint(x: size.width / 2, y: size.height * 0.22)
                    let r = max(size.width, size.height) * 1.5
                    var a = 0.0
                    while a < 360 {
                        var p = Path()
                        p.move(to: o)
                        p.addLine(to: CGPoint(x: o.x + r * cos(a * .pi / 180), y: o.y + r * sin(a * .pi / 180)))
                        p.addLine(to: CGPoint(x: o.x + r * cos((a + 5) * .pi / 180), y: o.y + r * sin((a + 5) * .pi / 180)))
                        p.closeSubpath()
                        ctx.fill(p, with: .color(.white.opacity(0.05)))
                        a += 12
                    }
                }
            }
        case .stripes:
            ZStack {
                LinearGradient(colors: [Color(red: 0.07, green: 0.13, blue: 0.29), Color(red: 0.04, green: 0.07, blue: 0.16), Color(red: 0.02, green: 0.04, blue: 0.10)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Canvas { ctx, size in
                    var x: CGFloat = -size.height
                    while x < size.width {
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: size.height))
                        p.addLine(to: CGPoint(x: x + size.height * 0.47, y: 0))
                        ctx.stroke(p, with: .color(.white.opacity(0.025)), lineWidth: 2)
                        x += 14
                    }
                }
            }
        case .sunset:
            ZStack {
                LinearGradient(colors: [Color(red: 0.10, green: 0.04, blue: 0.18), Color(red: 0.07, green: 0.02, blue: 0.12), Color(red: 0.04, green: 0.02, blue: 0.07)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(red: 0.89, green: 0.27, blue: 0.48).opacity(0.28), .clear],
                               center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: 320)
            }
        }
    }

    private var blobs: some View {
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
}

/// Classic desktop pattern: one black dot in every 2×2, offset each row.
enum DitherTile {
    static let image: UIImage = {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            ctx.fill(CGRect(x: 2, y: 2, width: 1, height: 1))
        }
    }()
}

// MARK: - Cards

struct GlacierCard: ViewModifier {
    var radius: CGFloat = 24
    var padding: CGFloat = 18
    var title: String? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        let inner = content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        switch Theme.skin.card {
        case .glacier:
            inner
                .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
                .shadow(color: Theme.shadow, radius: 14, x: 0, y: 6)
        case .pixel:
            inner
                .background(Theme.card)
                .overlay(Rectangle().strokeBorder(Theme.cardBorder, lineWidth: 3))
                .padding(5)
                .overlay(Rectangle().strokeBorder(Theme.cardBorder.opacity(0.85), lineWidth: 2))
        case .rule:
            content
                .padding(.vertical, max(10, padding * 0.7))
                .padding(.horizontal, padding == 0 ? 0 : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    VStack(spacing: 2) {
                        Rectangle().fill(Theme.ink).frame(height: 1.5)
                        Rectangle().fill(Theme.ink).frame(height: 0.75)
                    }
                }
        case .terminal:
            inner
                .background(Theme.card)
                .overlay(Rectangle().strokeBorder(Theme.cardBorder, lineWidth: 1))
        case .swiss:
            content
                .padding(.vertical, max(10, padding * 0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(Theme.ink).frame(height: 4) }
        case .aero:
            AeroWindow(title: title) { inner }
        case .window:
            MacWindow(title: title) { inner }
        case .panel:
            inner
                .background(Theme.card)
                .overlay(Rectangle().strokeBorder(Theme.cardBorder, lineWidth: 2))
        case .broadcast:
            inner
                .background(Theme.card)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 4) }
        case .vice:
            inner
                .background(Theme.card)
                .overlay(Rectangle().strokeBorder(Theme.cardBorder, lineWidth: 1))
        }
    }
}

extension View {
    /// Keeps the bottom of a scrolling screen clear of a theme's tab bar.
    @ViewBuilder
    func tabBarClearance() -> some View {
        if Theme.skin.tab == .system {
            self
        } else {
            self.safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: Theme.tabBarHeight).allowsHitTesting(false)
            }
        }
    }

    /// The skin's default type and caps, for sheets shown from the app root.
    func themedText() -> some View {
        self
            .font(Theme.font(size: 17))
            .textCase(Theme.skin.allCaps ? .uppercase : nil)
            .tint(Theme.accent)
    }

    func glacierCard(radius: CGFloat = 24, padding: CGFloat = 18, title: String? = nil) -> some View {
        modifier(GlacierCard(radius: radius, padding: padding, title: title))
    }
}

/// Windows 7 style glass frame around a white client area.
struct AeroWindow<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                Text(title ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.04, green: 0.14, blue: 0.25))
                    .shadow(color: .white, radius: 4)
                    .padding(.top, 7)
                Spacer(minLength: 0)
                AeroCaptionButtons()
            }
            .padding(.leading, 6)
            .frame(height: 28, alignment: .top)
            content
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(red: 0, green: 0.12, blue: 0.24).opacity(0.55), lineWidth: 1))
        }
        .padding([.horizontal, .bottom], 7)
        .background {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.78, green: 0.90, blue: 0.98).opacity(0.72),
                                                  Color(red: 0.59, green: 0.78, blue: 0.92).opacity(0.55),
                                                  Color(red: 0.47, green: 0.71, blue: 0.88).opacity(0.62)],
                                         startPoint: .top, endPoint: .bottom))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0)], startPoint: .topLeading, endPoint: UnitPoint(x: 0.5, y: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.75), lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color(red: 0, green: 0.1, blue: 0.22).opacity(0.55), lineWidth: 1).padding(-1))
        .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 8)
    }
}

struct AeroCaptionButtons: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(stops: [.init(color: .white.opacity(0.55), location: 0), .init(color: .white.opacity(0.45), location: 0.45),
                                             .init(color: Color(red: 0.67, green: 0.78, blue: 0.88).opacity(0.4), location: 0.5),
                                             .init(color: Color(red: 0.78, green: 0.88, blue: 0.96).opacity(0.5), location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 26, height: 18)
                .overlay(alignment: .bottom) { Rectangle().fill(.white).frame(width: 9, height: 2).padding(.bottom, 5) }
            Rectangle()
                .fill(LinearGradient(stops: [.init(color: Color(red: 0.91, green: 0.64, blue: 0.58), location: 0), .init(color: Color(red: 0.84, green: 0.38, blue: 0.29), location: 0.45),
                                             .init(color: Color(red: 0.76, green: 0.19, blue: 0.11), location: 0.5), .init(color: Color(red: 0.85, green: 0.34, blue: 0.25), location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 40, height: 18)
                .overlay(Image(systemName: "xmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white))
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5))
        .overlay(UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5).stroke(Color(red: 0, green: 0.12, blue: 0.24).opacity(0.55), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// Classic Mac window: striped title bar, 2pt frame and a hard shadow.
struct MacWindow<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                MacStripes()
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.white).frame(width: 18, height: 13)
                            .overlay(Rectangle().strokeBorder(.black, lineWidth: 2).frame(width: 11, height: 11))
                            .padding(.leading, 6)
                    }
                if let title {
                    Text(title)
                        .font(Theme.label(13, .bold))
                        .foregroundStyle(.black)
                        .fixedSize()
                    MacStripes()
                }
            }
            .padding(.horizontal, 4)
            .frame(height: 22)
            Rectangle().fill(.black).frame(height: 2)
            content
        }
        .background(Color.white)
        .overlay(Rectangle().strokeBorder(.black, lineWidth: 2))
        .background(Rectangle().fill(.black).offset(x: 3, y: 3))
    }
}

struct MacStripes: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black))
                y += 2
            }
        }
        .frame(height: 11)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// A slanted box for broadcast graphics.
struct Slant: Shape {
    var amount: CGFloat = 0.22
    func path(in rect: CGRect) -> Path {
        let d = rect.height * amount
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + d, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - d, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A hard outline around text, made of offset copies.
struct Outlined: ViewModifier {
    var color: Color = .black
    var width: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: 0, x: width, y: 0)
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: 0, y: -width)
    }
}

extension View {
    func outlined(_ color: Color = .black, width: CGFloat = 1.5) -> some View {
        modifier(Outlined(color: color, width: width))
    }

    /// Glass on Glacier; a flat chip that matches the skin elsewhere.
    @ViewBuilder
    func themedChipButton(circle: Bool = false) -> some View {
        if Theme.skin.isGlacier {
            if circle {
                self.buttonStyle(.glass).buttonBorderShape(.circle)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(ChipButtonStyle())
        }
    }
}

struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let r = Theme.radius(12)
        configuration.label
            .foregroundStyle(Theme.ink)
            .background(configuration.isPressed ? Theme.chip.opacity(0.7) : Theme.chip, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(Theme.fieldBorder, lineWidth: Theme.skin.card == .window ? 2 : 1))
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(Theme.skin.isGlacier ? .system(size: 15, weight: .bold) : Theme.label(15, .bold))
            .foregroundStyle(Theme.ink)
    }
}

struct Pill: View {
    let text: String
    var fill: Color = Theme.accentSoft
    var ink: Color = Theme.accentText

    var body: some View {
        Text(text)
            .font(Theme.label(11, .bold))
            .tracking(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.skin.isGlacier ? 20 : Theme.radius(6), style: .continuous))
            .foregroundStyle(ink)
    }
}

/// Main action on a screen, drawn in the skin's style.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        styled(configuration.label, pressed: pressed)
            .opacity(pressed ? 0.88 : 1)
            .scaleEffect(pressed ? 0.98 : 1)
    }

    @ViewBuilder
    private func styled(_ label: Configuration.Label, pressed: Bool) -> some View {
        switch Theme.skin.button {
        case .glacier:
            label
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(Theme.accentInk)
        case .block:
            label
                .font(Theme.label(15))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.accent)
                .overlay(alignment: .bottom) { Rectangle().fill(.black.opacity(0.22)).frame(height: 6) }
                .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.4)).frame(height: 4) }
                .foregroundStyle(Theme.accentInk)
        case .ink:
            label
                .font(Theme.label(15, .heavy))
                .tracking(0.6)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Theme.accent)
                .foregroundStyle(Theme.accentInk)
        case .prompt:
            HStack(spacing: 10) {
                Text("⏎")
                    .font(Theme.font(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .background(Theme.accent)
                    .foregroundStyle(Theme.accentInk)
                label.font(Theme.font(size: 16, weight: .heavy))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.accent.opacity(pressed ? 0.18 : 0.08))
            .overlay(Rectangle().strokeBorder(Theme.accent, lineWidth: 1.5))
            .foregroundStyle(Theme.accent)
        case .swiss:
            label
                .font(Theme.display(20))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Theme.accent)
                .foregroundStyle(Theme.accentInk)
        case .gel:
            label
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    LinearGradient(stops: [.init(color: Color(red: 0.95, green: 0.98, blue: 1), location: 0),
                                           .init(color: Color(red: 0.86, green: 0.94, blue: 0.99), location: 0.48),
                                           .init(color: Color(red: 0.71, green: 0.87, blue: 0.97), location: 0.5),
                                           .init(color: Color(red: 0.80, green: 0.92, blue: 0.98), location: 1)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0.17, green: 0.38, blue: 0.55), lineWidth: 1))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.8), lineWidth: 1).padding(1))
                .shadow(color: Color(red: 0.36, green: 0.71, blue: 0.94).opacity(pressed ? 0.9 : 0.6), radius: 6)
                .foregroundStyle(Color(red: 0.04, green: 0.14, blue: 0.25))
        case .mac:
            label
                .font(Theme.font(size: 17, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(pressed ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(pressed ? Color.white : Color.black)
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.black, lineWidth: 2))
                .padding(5)
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(.black, lineWidth: 3))
        case .bell:
            label
                .font(Theme.display(22, .regular))
                .tracking(2)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(LinearGradient(colors: [Color(red: 1, green: 0.26, blue: 0.35), Color(red: 0.84, green: 0.15, blue: 0.24), Color(red: 0.64, green: 0.07, blue: 0.16)],
                                           startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().strokeBorder(Color(red: 1, green: 0.83, blue: 0.28), lineWidth: 3))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.43, green: 0.04, blue: 0.09), radius: 0, x: 0, y: 6)
        case .skew:
            label
                .font(Theme.display(24, .heavy))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(LinearGradient(colors: [Color(red: 1, green: 0.83, blue: 0.31), Color(red: 1, green: 0.72, blue: 0)], startPoint: .top, endPoint: .bottom),
                            in: Slant(amount: 0.2))
                .foregroundStyle(Color(red: 0.04, green: 0.07, blue: 0.16))
                .shadow(color: Color(red: 0.7, green: 0.5, blue: 0), radius: 0, x: 0, y: 5)
        case .vice:
            label
                .font(Theme.display(26, .bold))
                .tracking(1.2)
                .foregroundStyle(.white)
                .outlined(Color(red: 0.04, green: 0.02, blue: 0.07), width: 1.6)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(LinearGradient(colors: [Color(red: 1, green: 0.31, blue: 0.60), Color(red: 1, green: 0.48, blue: 0.35), Color(red: 1, green: 0.70, blue: 0.28)],
                                           startPoint: .leading, endPoint: .trailing))
                .overlay(Rectangle().strokeBorder(Color(red: 0.04, green: 0.02, blue: 0.07), lineWidth: 3))
                .shadow(color: Color(red: 1, green: 0.31, blue: 0.60).opacity(0.45), radius: 11, y: 8)
        }
    }
}

/// Outlined secondary button.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let r = Theme.radius(14)
        configuration.label
            .font(Theme.font(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(configuration.isPressed ? Theme.chip : Color.clear, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(Theme.fieldBorder, lineWidth: Theme.skin.card == .window ? 2 : 1))
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
