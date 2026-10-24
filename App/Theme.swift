import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 0.16, green: 0.47, blue: 0.93)
    static let sky = Color(red: 0.36, green: 0.68, blue: 0.98)
}

/// Sky gradient behind everything. Liquid Glass needs color behind it to read well.
struct SkyBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.03, green: 0.08, blue: 0.17),
                   Color(red: 0.06, green: 0.19, blue: 0.38),
                   Color(red: 0.04, green: 0.11, blue: 0.24)]
                : [Color(red: 0.89, green: 0.95, blue: 1.00),
                   Color(red: 0.68, green: 0.85, blue: 0.99),
                   Color(red: 0.84, green: 0.92, blue: 1.00)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
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
        let unit = ex.timed ? "s" : ""
        let side = ex.perSide ? " per side" : ""
        return "\(sets) × \(rangeText)\(unit)\(side) · \(rest)s rest"
    }
}
