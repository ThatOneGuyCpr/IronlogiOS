import SwiftUI

@main
struct IronlogApp: App {
    @StateObject private var store = Store()
    @StateObject private var rest = RestController()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(rest)
                .onOpenURL { _ in
                    // Shortcuts sends us back here after saving to Health.
                }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase != .active { store.saveNow() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        TabView {
            Tab("Train", systemImage: "dumbbell.fill") {
                TrainTab()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
            Tab("Settings", systemImage: "slider.horizontal.3") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .sheet(item: $store.lastFinished) { entry in
            FinishSheet(entry: entry)
                .presentationDetents([.medium])
        }
    }
}

struct TrainTab: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        if store.data.session != nil {
            WorkoutView()
        } else {
            TodayView()
        }
    }
}
