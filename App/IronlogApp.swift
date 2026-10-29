import SwiftUI

@main
struct IronlogApp: App {
    @StateObject private var store = Store()
    @StateObject private var rest = RestController()
    @Environment(\.scenePhase) private var phase

    init() {
        Clips.configureAudio()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(rest)
                .preferredColorScheme((Appearance(rawValue: store.data.appearance) ?? .system).scheme)
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase != .active {
                store.saveNow()
                store.syncWidget()
            }
        }
    }
}

enum AppTab: Hashable {
    case train, progress, history, settings
}

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController
    @State private var tab: AppTab = .train
    @State private var notice: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $tab) {
            Tab("Train", systemImage: "dumbbell.fill", value: AppTab.train) {
                TrainTab()
            }
            Tab("Progress", systemImage: "chart.bar.fill", value: AppTab.progress) {
                ProgressTab()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Settings", systemImage: "slider.horizontal.3", value: AppTab.settings) {
                SettingsView()
            }
        }
        // Colors are read from the theme when views draw, so rebuild everything when the look changes.
        .id(store.lookID)
        .tint(Theme.accent)
        .overlay(alignment: .top) {
            if let c = store.celebration {
                ZStack(alignment: .top) {
                    if !reduceMotion {
                        ConfettiView()
                            .ignoresSafeArea()
                    }
                    RecordBanner(celebration: c)
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                .task(id: c.id) {
                    try? await Task.sleep(for: .seconds(3.2))
                    if store.celebration?.id == c.id {
                        withAnimation(.snappy) { store.celebration = nil }
                    }
                }
            }
        }
        .animation(.snappy, value: store.celebration)
        .sensoryFeedback(.success, trigger: store.celebration?.id) { _, new in new != nil }
        .sheet(item: $store.lastFinished) { entry in
            FinishSheet(entry: entry)
                .presentationDetents([.medium, .large])
        }
        .onOpenURL { url in handle(url) }
        .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK") { notice = nil }
        }
    }

    /// Links from widgets: ironlog://start and ironlog://moveup/<exercise id>.
    /// Shortcuts also returns here with ironlog://health-saved, which needs nothing.
    private func handle(_ url: URL) {
        guard url.scheme == "ironlog" else { return }
        switch url.host {
        case "start":
            tab = .train
            if store.data.session == nil {
                beginWorkout(store: store, rest: rest)
            }
        case "moveup":
            tab = .progress
            let id = url.lastPathComponent
            if let p = store.stallPrompts().first(where: { $0.id == id }) {
                store.acceptStall(p)
                notice = "Your next \(p.name.lowercased()) will load \(Store.fmt(p.next)) lb."
            }
        default:
            break
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
