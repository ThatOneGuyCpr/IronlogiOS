import SwiftUI

@main
struct IronlogWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHome()
        }
    }
}

struct WatchHome: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ironlog")
                    .font(.headline)
                Text("Watch test build. If you can read this, the Watch app installed.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(RoutineID.cycle) { r in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.title).font(.body.weight(.semibold))
                        Text(r.subtitle).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(red: 0.33, green: 0.66, blue: 0.97).opacity(0.25),
                                in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}
