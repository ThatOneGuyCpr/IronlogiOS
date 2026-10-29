import SwiftUI
import UIKit

/// Home screen icons. Each alternate lives in the asset catalog as AppIcon-<id>,
/// with a small IconPreview-<id> image for the picker.
struct AppIconOption: Identifiable, Hashable {
    let id: String
    let name: String
    let group: String
    /// Color theme that goes with it, offered when you switch.
    let palette: String

    /// Name passed to setAlternateIconName. nil is the primary icon.
    var assetName: String? { id == "glacier" ? nil : "AppIcon-\(id)" }
    var preview: String { "IconPreview-\(id)" }
}

enum AppIcons {
    static let all: [AppIconOption] = [
        AppIconOption(id: "glacier", name: "Glacier", group: "Classic", palette: "glacier"),
        AppIconOption(id: "pixel", name: "8-Bit", group: "Video game", palette: "grape"),
        AppIconOption(id: "pocket", name: "Pocket", group: "Video game", palette: "volt"),
        AppIconOption(id: "arcade", name: "Arcade", group: "Video game", palette: "grape"),
        AppIconOption(id: "loot", name: "Loot", group: "Video game", palette: "gold"),
        AppIconOption(id: "levelup", name: "Level Up", group: "Video game", palette: "mint"),
        AppIconOption(id: "mainevent", name: "Main Event", group: "80s wrestling", palette: "rose"),
        AppIconOption(id: "titlebelt", name: "Title Belt", group: "80s wrestling", palette: "gold"),
        AppIconOption(id: "grit", name: "Grit", group: "80s wrestling", palette: "rose"),
        AppIconOption(id: "studio", name: "Studio", group: "Minimal", palette: "mono"),
        AppIconOption(id: "graphite", name: "Graphite", group: "Minimal", palette: "mono"),
        AppIconOption(id: "ember", name: "Ember", group: "Fitness", palette: "ember"),
        AppIconOption(id: "blackout", name: "Blackout", group: "Fitness", palette: "volt"),
    ]

    static var groups: [String] {
        var seen: [String] = []
        for o in all where !seen.contains(o.group) { seen.append(o.group) }
        return seen
    }

    static var current: AppIconOption {
        let name = UIApplication.shared.alternateIconName
        return all.first { $0.assetName == name } ?? all[0]
    }

    @MainActor
    static func set(_ option: AppIconOption) async -> String? {
        guard UIApplication.shared.supportsAlternateIcons else { return "This install doesn't support changing the icon." }
        if UIApplication.shared.alternateIconName == option.assetName { return nil }
        do {
            try await UIApplication.shared.setAlternateIconName(option.assetName)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

/// Grid of icons used in Settings.
struct IconPicker: View {
    @EnvironmentObject private var store: Store
    @State private var current: AppIconOption = AppIcons.current
    @State private var suggestion: Palette?
    @State private var error: String?

    private let columns = [GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(AppIcons.groups, id: \.self) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.sub)
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(AppIcons.all.filter { $0.group == group }) { option in
                            cell(option)
                        }
                    }
                }
            }
            if let suggestion {
                HStack(spacing: 10) {
                    Circle().fill(suggestion.accentColor).frame(width: 22, height: 22)
                    Text("Match the color too?")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button("Use \(suggestion.name)") {
                        store.data.accent = suggestion.id
                    }
                    .buttonStyle(.glassProminent)
                    .tint(suggestion.accentColor)
                    Button {
                        withAnimation { self.suggestion = nil }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.sub)
                    .accessibilityLabel("Keep current color")
                }
                .padding(12)
                .background(Theme.promptBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if let error {
                Text(error).font(.caption).foregroundStyle(Theme.warn)
            }
        }
        .padding(.vertical, 6)
    }

    private func cell(_ option: AppIconOption) -> some View {
        let selected = option.id == current.id
        return Button {
            Task {
                let failure = await AppIcons.set(option)
                error = failure
                guard failure == nil else { return }
                current = option
                withAnimation {
                    suggestion = option.palette == store.data.accent ? nil : Palette.named(option.palette)
                }
            }
        } label: {
            VStack(spacing: 5) {
                Image(option.preview)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13.5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Theme.accent : Color.clear, lineWidth: 2.5)
                            .padding(-3)
                    )
                Text(option.name)
                    .font(.system(size: 11, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? Theme.accentText : Theme.sub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.name) icon")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Row of color swatches used in Settings.
struct ColorPickerRow: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Color")
                Spacer()
                Text(Palette.named(store.data.accent).name).foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(Palette.all) { p in
                    let selected = p.id == store.data.accent
                    Button {
                        store.data.accent = p.id
                    } label: {
                        Circle()
                            .fill(LinearGradient(colors: [p.swatchLight, p.swatchDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .padding(4)
                            .overlay(Circle().stroke(selected ? Color.primary : Color.clear, lineWidth: 2))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(p.name)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}
