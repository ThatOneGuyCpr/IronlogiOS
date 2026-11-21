import SwiftUI

// Pieces only some themes use: custom tab bars, chrome titles, the HUD and the theme picker.

// MARK: - Tab bars

struct ThemedTabBar: View {
    @Binding var tab: AppTab
    private let items: [(AppTab, String)] = [
        (.train, "dumbbell.fill"), (.progress, "chart.bar.fill"),
        (.history, "clock.arrow.circlepath"), (.settings, "slider.horizontal.3"),
    ]

    var body: some View {
        bar
            .sensoryFeedback(.selection, trigger: tab)
    }

    private func name(_ i: Int) -> String {
        let t = Theme.words.tabs
        return i < t.count ? t[i] : ""
    }

    private func select(_ t: AppTab) {
        tab = t
    }

    @ViewBuilder
    private var bar: some View {
        switch Theme.skin.tab {
        case .system:
            EmptyView()
        case .block:
            let eight = Theme.skin.id == "8bit"
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let on = items[i].0 == tab
                    Button { select(items[i].0) } label: {
                        Text(name(i))
                            .font(Theme.label(eight ? 13 : 14, .bold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(on ? Theme.accent : Color.clear)
                            .foregroundStyle(on ? Theme.accentInk : Theme.sub)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .frame(height: 58)
            .background(Theme.tabBg)
            .overlay(Rectangle().strokeBorder(eight ? Color.white : Theme.faint, lineWidth: eight ? 3 : 1))
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
        case .text:
            let swiss = Theme.skin.id == "swiss"
            VStack(spacing: 0) {
                if swiss {
                    Rectangle().fill(Theme.ink).frame(height: 4)
                } else {
                    VStack(spacing: 2) {
                        Rectangle().fill(Theme.ink).frame(height: 1)
                        Rectangle().fill(Theme.ink).frame(height: 1)
                    }
                }
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        let on = items[i].0 == tab
                        Button { select(items[i].0) } label: {
                            Text(name(i))
                                .font(swiss ? Theme.display(12) : Theme.label(12, .heavy))
                                .tracking(swiss ? 0 : 0.8)
                                .textCase(.uppercase)
                                .foregroundStyle(on ? Theme.accentText : Theme.ink)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .overlay(alignment: .top) {
                                    if on && !swiss { Rectangle().fill(Theme.accentText).frame(height: 3) }
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            .padding(.horizontal, swiss ? 20 : 8)
            .background(Theme.tabBg.ignoresSafeArea(edges: .bottom))
        case .taskbar:
            HStack(spacing: 4) {
                AeroOrb(size: 44)
                    .padding(.trailing, 4)
                ForEach(0..<4, id: \.self) { i in
                    let on = items[i].0 == tab
                    Button { select(items[i].0) } label: {
                        VStack(spacing: 2) {
                            Image(systemName: items[i].1).font(.system(size: 17, weight: .semibold))
                            Text(name(i)).font(.system(size: 10.5))
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
                        .frame(width: 60, height: 46)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [.white.opacity(0.32), .white.opacity(0.08), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                                    .overlay(RadialGradient(colors: [Color(red: 0.47, green: 0.86, blue: 1).opacity(0.75), .clear], center: UnitPoint(x: 0.5, y: 1.1), startRadius: 0, endRadius: 34))
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.45), lineWidth: 1))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(name(i))
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
                Spacer(minLength: 0)
                VStack(spacing: 1) {
                    Text(Date(), style: .time)
                    Text(Date().formatted(.dateTime.month(.defaultDigits).day().year()))
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                LinearGradient(colors: [Color(red: 0.59, green: 0.78, blue: 0.92).opacity(0.42), Color(red: 0.16, green: 0.31, blue: 0.47).opacity(0.6), Color(red: 0.04, green: 0.12, blue: 0.22).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.55)).frame(height: 1) }
                    .ignoresSafeArea(edges: .bottom)
            }
        case .window:
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let on = items[i].0 == tab
                    Button { select(items[i].0) } label: {
                        VStack(spacing: 3) {
                            Image(systemName: items[i].1).font(.system(size: 15, weight: .bold))
                            Text(name(i)).font(Theme.font(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(on ? Color.black : Color.white)
                        .foregroundStyle(on ? Color.white : Color.black)
                        .overlay(alignment: .leading) {
                            if i > 0 { Rectangle().fill(.black).frame(width: 2) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .frame(height: 58)
            .overlay(Rectangle().strokeBorder(.black, lineWidth: 2))
            .background(Rectangle().fill(.black).offset(x: 3, y: 3))
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        case .ropes:
            VStack(spacing: 0) {
                RingRopes()
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        let on = items[i].0 == tab
                        Button { select(items[i].0) } label: {
                            Text(name(i))
                                .font(Theme.display(15, .regular))
                                .tracking(1.4)
                                .foregroundStyle(on ? Theme.accentText : Theme.sub)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            .background(Theme.tabBg.ignoresSafeArea(edges: .bottom))
        case .underline:
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let on = items[i].0 == tab
                    Button { select(items[i].0) } label: {
                        Text(name(i))
                            .font(Theme.label(16, .heavy))
                            .tracking(1.2)
                            .foregroundStyle(on ? Theme.ink : Theme.sub)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .overlay(alignment: .top) { Rectangle().fill(on ? Theme.accent : Color.clear).frame(height: 4) }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .background(Theme.tabBg.ignoresSafeArea(edges: .bottom))
        case .pause:
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    let on = items[i].0 == tab
                    Button { select(items[i].0) } label: {
                        Text(name(i))
                            .font(Theme.display(17, .regular))
                            .tracking(0.8)
                            .foregroundStyle(on ? Color(red: 0.04, green: 0.02, blue: 0.07) : .white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(on ? Color.white : Color(red: 0.04, green: 0.02, blue: 0.07).opacity(0.75))
                            .overlay(alignment: .top) { Rectangle().fill(on ? Theme.accent : Color.clear).frame(height: 3) }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 2)
            .background(LinearGradient(colors: [Theme.tabBg.opacity(0), Theme.tabBg], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35)).ignoresSafeArea(edges: .bottom))
        }
    }
}

/// Red, white and blue ring ropes.
struct RingRopes: View {
    var body: some View {
        VStack(spacing: 1.5) {
            Rectangle().fill(Color(red: 0.84, green: 0.15, blue: 0.24)).frame(height: 3)
            Rectangle().fill(Color.white).frame(height: 3)
            Rectangle().fill(Color(red: 0.16, green: 0.36, blue: 0.84)).frame(height: 3)
        }
        .accessibilityHidden(true)
    }
}

/// The glass orb from the Aero icon.
struct AeroOrb: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(red: 0.9, green: 0.96, blue: 1), Color(red: 0.37, green: 0.49, blue: 0.58), Color(red: 0.1, green: 0.16, blue: 0.22)], startPoint: .top, endPoint: .bottom))
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.5, green: 0.9, blue: 1), Color(red: 0.12, green: 0.56, blue: 0.86), Color(red: 0.04, green: 0.31, blue: 0.6)],
                                     center: UnitPoint(x: 0.5, y: 0.62), startRadius: 0, endRadius: size * 0.55))
                .padding(size * 0.06)
            Image(systemName: "dumbbell.fill")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.6, green: 0.95, blue: 1), radius: 3)
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.74, height: size * 0.38)
                .offset(y: -size * 0.2)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 0.47, green: 0.86, blue: 1).opacity(0.6), radius: 6)
        .accessibilityHidden(true)
    }
}

// MARK: - Title treatments

extension View {
    /// Leans the view right, like a fight poster or a broadcast graphic.
    func lean(_ k: CGFloat, height: CGFloat) -> some View {
        transformEffect(CGAffineTransform(a: 1, b: 0, c: -k, d: 1, tx: k * height / 2, ty: 0))
    }
}

/// Chrome lettering for the Main Event poster.
struct ChromeTitle: View {
    let text: String
    var size: CGFloat

    var body: some View {
        Text(text.uppercased())
            .font(Theme.display(size, .regular))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(LinearGradient(stops: [
                .init(color: Color(red: 0.96, green: 0.98, blue: 1), location: 0),
                .init(color: Color(red: 0.62, green: 0.83, blue: 0.96), location: 0.4),
                .init(color: Color(red: 0.15, green: 0.25, blue: 0.44), location: 0.49),
                .init(color: Color(red: 0.97, green: 0.71, blue: 0.36), location: 0.54),
                .init(color: Color(red: 1, green: 0.95, blue: 0.82), location: 0.78),
                .init(color: Color(red: 0.97, green: 0.71, blue: 0.36), location: 1),
            ], startPoint: .top, endPoint: .bottom))
            .shadow(color: Color(red: 0.84, green: 0.15, blue: 0.24), radius: 0, x: 0, y: 4)
            .shadow(color: Color(red: 0.16, green: 0.04, blue: 0.23), radius: 0, x: 0, y: 4)
            .lean(0.14, height: size)
    }
}

/// Wanted-level stars for the Vice City HUD.
struct WantedStars: View {
    let filled: Int
    let total: Int
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(i < filled ? Color.white : Color.white.opacity(0.14))
                    .outlined(Color(red: 0.04, green: 0.02, blue: 0.07), width: 1)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(filled) of \(total) workouts this week")
    }
}

enum ViceText {
    /// "Get to the gym and work your chest, back and arms." with the GTA objective colors.
    static func objective(_ subtitle: String) -> Text {
        let yellow = Color(red: 0.94, green: 0.78, blue: 0.31)
        let blue = Color(red: 0.43, green: 0.76, blue: 1)
        var parts = subtitle.components(separatedBy: ", ").map { $0.lowercased() }
        var t = Text("Get to the ") + Text("gym").foregroundColor(yellow)
        if parts.first?.hasPrefix("every muscle") == true {
            return t + Text(" and hit ") + Text("every muscle").foregroundColor(blue) + Text(".")
        }
        t = t + Text(" and work your ")
        if parts.count > 1 {
            let last = parts.removeLast()
            for (i, p) in parts.enumerated() {
                t = t + Text(p).foregroundColor(blue) + Text(i < parts.count - 1 ? ", " : " and ")
            }
            t = t + Text(last).foregroundColor(blue)
        } else if let only = parts.first {
            t = t + Text(only).foregroundColor(blue)
        }
        return t + Text(".")
    }
}

// MARK: - Theme picker

struct ThemePickerView: View {
    @EnvironmentObject private var store: Store
    @State private var error: String?
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Changes the type, shapes, textures and colors across the app and widgets.")
                        .font(Theme.font(size: 14))
                        .foregroundStyle(Theme.sub)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Skin.all) { s in
                            tile(s).id(s.id)
                        }
                    }
                }
                .glacierCard(radius: 20, padding: 14, title: "Themes")
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $store.data.skinIcon) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Switch app icon too").font(Theme.font(size: 15, weight: .semibold))
                            Text("Uses the theme's matching icon").font(Theme.font(size: 12)).foregroundStyle(Theme.sub)
                        }
                    }
                    if !Theme.skin.isGlacier {
                        Rectangle().fill(Theme.faint).frame(height: 1)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Color").font(Theme.font(size: 15, weight: .semibold))
                                Spacer()
                                Text(store.data.skinColor == "theme" ? "Theme's" : Palette.named(store.data.skinColor).name)
                                    .font(Theme.font(size: 14))
                                    .foregroundStyle(Theme.sub)
                            }
                            HStack(spacing: 0) {
                                swatch("theme", fill: AnyShapeStyle(Theme.skin.colors.map { $0.accent.color } ?? Theme.accent), label: "Theme's color")
                                ForEach(Palette.all) { p in
                                    swatch(p.id, fill: AnyShapeStyle(LinearGradient(colors: [p.swatchLight, p.swatchDark], startPoint: .topLeading, endPoint: .bottomTrailing)), label: p.name)
                                }
                            }
                        }
                    }
                }
                .foregroundStyle(Theme.ink)
                .glacierCard(radius: 20, padding: 16)
                if let error {
                    Text(error)
                        .font(Theme.font(size: 12))
                        .foregroundStyle(Theme.ink)
                        .glacierCard(radius: 16, padding: 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .onAppear {
            // The picker rebuilds with each theme; land back on the one just picked.
            proxy.scrollTo(store.data.skin, anchor: .center)
        }
        }
        .background { SkyBackground() }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func swatch(_ id: String, fill: AnyShapeStyle, label: String) -> some View {
        let selected = store.data.skinColor == id
        return Button {
            store.data.skinColor = id
        } label: {
            Circle()
                .fill(fill)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Theme.ink.opacity(0.15), lineWidth: 1))
                .overlay {
                    if id == "theme" {
                        Image(systemName: "paintpalette.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).shadow(radius: 1)
                    }
                }
                .padding(3)
                .overlay(Circle().stroke(selected ? Theme.ink : Color.clear, lineWidth: 2))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func tile(_ s: Skin) -> some View {
        let selected = s.id == store.data.skin
        return Button {
            pick(s)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                ThemeSwatch(skin: s)
                    .frame(height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Theme.accent : Color.clear, lineWidth: 3)
                            .padding(-4)
                    )
                    .overlay(alignment: .topTrailing) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Theme.accent)
                                .padding(4)
                        }
                    }
                Text(s.name)
                    .font(Theme.font(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .textCase(nil)
                Text(s.blurb)
                    .font(Theme.font(size: 11))
                    .foregroundStyle(Theme.sub)
                    .textCase(nil)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(s.name) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func pick(_ s: Skin) {
        let switchIcon = store.data.skinIcon
        store.data.skin = s.id
        store.data.skinColor = "theme"
        guard switchIcon else { return }
        let iconID = s.isGlacier ? "glacier" : s.icon
        guard let iconID, let option = AppIcons.all.first(where: { $0.id == iconID }) else { return }
        Task {
            error = await store.setIcon(option)
        }
    }
}

/// A small sample of a skin, drawn from its own colors and type.
struct ThemeSwatch: View {
    let skin: Skin

    var body: some View {
        let c = skin.colors
        ZStack(alignment: .bottomLeading) {
            background(c)
            VStack(alignment: .leading, spacing: 5) {
                Text("Upper A")
                    .font(skin.isGlacier ? .system(size: 12, weight: .heavy) : skin.display.font(12, .heavy))
                    .textCase(skin.allCaps || skin.titleCaps ? .uppercase : nil)
                    .foregroundStyle(skin.card == .aero ? Color(red: 0.12, green: 0.25, blue: 0.54) : (c?.ink.color ?? Color(red: 0.04, green: 0.11, blue: 0.18)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Rectangle()
                    .fill(c?.accent.color ?? Color(red: 0.12, green: 0.44, blue: 0.92))
                    .frame(height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: skin.isGlacier ? 5 : min(4, skin.cardRadius)))
            }
            .padding(7)
            .background(cardFill(c))
            .overlay(cardStroke(c))
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.1), lineWidth: 1))
        .environment(\.colorScheme, skin.scheme ?? .light)
    }

    @ViewBuilder
    private func background(_ c: SkinColors?) -> some View {
        switch skin.backdrop {
        case .glacier:
            Color(red: 0.93, green: 0.95, blue: 0.98)
        case .aurora:
            LinearGradient(colors: [Color(red: 0.02, green: 0.2, blue: 0.37), Color(red: 0.11, green: 0.56, blue: 0.79), Color(red: 0.5, green: 0.89, blue: 0.69).opacity(0.8), Color(red: 0.09, green: 0.47, blue: 0.72)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dither:
            Image(uiImage: DitherTile.image).resizable(resizingMode: .tile).interpolation(.none)
        case .sunset:
            LinearGradient(colors: [Color(red: 0.12, green: 0.04, blue: 0.24), Color(red: 0.42, green: 0.11, blue: 0.43), Color(red: 0.89, green: 0.27, blue: 0.48), Color(red: 1, green: 0.54, blue: 0.3)],
                           startPoint: .top, endPoint: .bottom)
        case .rays:
            RadialGradient(colors: [Color(red: 0.12, green: 0.17, blue: 0.47), Color(red: 0.02, green: 0.03, blue: 0.11)], center: .top, startRadius: 0, endRadius: 120)
        default:
            LinearGradient(colors: [c?.bg.color ?? .white, c?.bg2.color ?? .white], startPoint: .top, endPoint: .bottom)
        }
    }

    private func cardFill(_ c: SkinColors?) -> Color {
        switch skin.card {
        case .glacier, .aero, .window: return .white
        case .rule, .swiss: return .clear
        default: return c?.card.color ?? .white
        }
    }

    @ViewBuilder
    private func cardStroke(_ c: SkinColors?) -> some View {
        switch skin.card {
        case .pixel: Rectangle().strokeBorder(Color.white, lineWidth: 2)
        case .window: Rectangle().strokeBorder(Color.black, lineWidth: 2)
        case .rule, .swiss: VStack { Rectangle().fill(c?.ink.color ?? .black).frame(height: 2); Spacer() }
        case .terminal, .panel, .vice: Rectangle().strokeBorder(c?.cardBorder.color ?? .clear, lineWidth: 1)
        case .aero: RoundedRectangle(cornerRadius: 3).strokeBorder(Color(red: 0.3, green: 0.42, blue: 0.53), lineWidth: 1)
        default: EmptyView()
        }
    }
}
