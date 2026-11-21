import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.openURL) private var openURL
    @State private var importing = false
    @State private var message: String?
    @State private var exportURL: URL?
    @State private var confirmErase = false
    @State private var showPlans = false

    var body: some View {
        NavigationStack {
            Form {
                Group {
                Section(header: FormHeader("Look")) {
                    Button {
                        store.showThemes = true
                    } label: {
                        HStack(spacing: 12) {
                            ThemeSwatch(skin: Theme.skin)
                                .frame(width: 54, height: 40)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Theme").foregroundStyle(Theme.ink)
                                Text(Theme.skin.name).font(Theme.font(size: 13)).foregroundStyle(Theme.sub)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.sub)
                        }
                    }
                    if Theme.skin.isGlacier {
                        Picker("Appearance", selection: $store.data.appearance) {
                            ForEach(Appearance.allCases) { a in
                                Text(a.label).tag(a.rawValue)
                            }
                        }
                        ColorPickerRow()
                        Picker("Background", selection: $store.data.background) {
                            ForEach(BackgroundStyle.allCases) { b in
                                Text(b.label).tag(b.rawValue)
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Numbers", selection: $store.data.numberStyle) {
                                ForEach(NumberStyle.allCases) { n in
                                    Text(n.label).tag(n.rawValue)
                                }
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text("185").font(Theme.num(34))
                                Text("lb").font(Theme.font(size: 15, weight: .semibold)).foregroundStyle(.secondary)
                                Spacer()
                                Text("1:30").font(Theme.num(28))
                                    .foregroundStyle(Theme.accentText)
                            }
                            .accessibilityHidden(true)
                        }
                    }
                    Toggle("Celebrate records", isOn: $store.data.celebrations)
                }

                Section(header: FormHeader("App icon")) {
                    IconPicker()
                }

                Section {
                    Picker("Rest timer", selection: $store.data.restStyle) {
                        Text("Bar").tag("bar")
                        Text("Big ring").tag("ring")
                    }
                    Toggle("Compact mode", isOn: $store.data.compact)
                } header: {
                    FormHeader("Workout screen")
                } footer: {
                    FormFooter("Compact mode tightens the set rows and tucks the form video behind a play button, so more fits on screen.")
                }

                Section(header: FormHeader("Goals")) {
                    Button {
                        showPlans = true
                    } label: {
                        LabeledContent("Plan") {
                            Text(store.data.plan.name).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    Toggle("Pair supersets by default", isOn: $store.data.supersetsByDefault)
                }

                Section(header: FormHeader("What's open by default")) {
                    EquipmentChips()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }

                Section(header: FormHeader("Exercises")) {
                    NavigationLink("Sets, reps and rest") { ExerciseListView() }
                    NavigationLink {
                        HiddenListView()
                    } label: {
                        HStack {
                            Text("Hidden exercises")
                            Spacer()
                            Text("\(store.data.hidden.count)").foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Save workouts to Health", isOn: $store.data.healthViaShortcut)
                    if store.data.healthViaShortcut {
                        TextField("Shortcut name", text: $store.data.shortcutName)
                            .autocorrectionDisabled()
                        Button("Test with a 1-minute workout") {
                            if let url = store.healthShortcutURL(minutes: 1) { openURL(url) }
                        }
                        DisclosureGroup("How to set up the shortcut") {
                            Text("""
                            1. Open Shortcuts and make a new shortcut named exactly "\(store.data.shortcutName)".
                            2. Add "Adjust Date". Set it to subtract Shortcut Input minutes from Current Date.
                            3. Add "Log Workout". Set the type to Traditional Strength Training, Date to the Adjusted Date, and Duration to Shortcut Input minutes.
                            4. If Shortcut Input isn't offered, open the shortcut's details and turn on receiving Text input.
                            5. Come back here and tap the test button. The first run asks for Health permission.
                            """)
                            .font(Theme.style(.callout))
                        }
                    }
                } header: {
                    FormHeader("Apple Health")
                } footer: {
                    FormFooter("SideStore can't grant direct Health access, so Ironlog hands each workout to a shortcut that logs it.")
                }

                Section {
                    Button("Import a backup") { importing = true }
                    if let exportURL {
                        ShareLink("Export a backup", item: exportURL)
                    }
                    DisclosureGroup("Set up automatic daily backups") {
                        Text("""
                        1. Open Shortcuts, go to Automation, tap +, and pick Time of Day. Choose a time (3:00 AM works), Daily, and Run Immediately.
                        2. Add the action "Export Ironlog Backup".
                        3. Add "Save File". Turn off Ask Where to Save, set the folder (for example iCloud Drive › Shortcuts › Ironlog), and turn on Overwrite If File Exists.
                        That's it. Your latest backup stays in iCloud Drive. To restore, tap Import a backup and pick that file.
                        """)
                        .font(Theme.style(.callout))
                    }
                } header: {
                    FormHeader("Backup")
                } footer: {
                    FormFooter("Workouts live only on this phone. The daily automation keeps a copy in iCloud Drive without you doing anything.")
                }

                Section {
                    LabeledContent("Widget storage", value: SharedStore.groupWorks ? "OK" : "Not available")
                    LabeledContent("Signing", value: Provisioning.summary)
                        .font(Theme.style(.caption))
                    LabeledContent("Version", value: appVersion)
                } header: {
                    FormHeader("Diagnostics")
                }

                Section {
                    Button("Erase all data", role: .destructive) { confirmErase = true }
                }
                }
                .listRowBackground(Theme.row)
            }
            .scrollContentBackground(.hidden)
            .tabBarClearance()
            .background { SkyBackground(calm: true) }
            .navigationTitle(Theme.skin.isGlacier ? "Settings" : Theme.words.tabs[3])
            .onAppear { exportURL = store.exportFileURL() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert("Import", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: {
                Text(message ?? "")
            }
            .sheet(isPresented: $showPlans) { ProgramsView() }
            .confirmationDialog("Erase every workout and setting?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase", role: .destructive) { store.eraseAll() }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            message = error.localizedDescription
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let raw = try Data(contentsOf: url)
                let count = try store.importBackup(raw)
                message = count == 1 ? "Imported 1 workout." : "Imported \(count) workouts."
                exportURL = store.exportFileURL()
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

struct ExerciseListView: View {
    @EnvironmentObject private var store: Store
    @State private var editing: IDBox?

    var body: some View {
        List(Library.all) { ex in
            Button {
                editing = IDBox(id: ex.id)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name).foregroundStyle(Theme.ink)
                        Text(store.basePrescription(ex.id).summary(for: ex))
                            .font(Theme.style(.caption))
                            .foregroundStyle(Theme.sub)
                    }
                    Spacer()
                    if store.isCustom(ex.id) {
                        Text("Custom")
                            .font(Theme.style(.caption2, .bold))
                            .foregroundStyle(Theme.accentText)
                    }
                }
            }
            .listRowBackground(Theme.row)
        }
        .scrollContentBackground(.hidden)
        .tabBarClearance()
        .background { SkyBackground(calm: true) }
        .navigationTitle("Sets, reps and rest")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { box in
            ExerciseSettingsSheet(exerciseID: box.id)
                .presentationDetents([.medium, .large])
        }
    }
}

struct HiddenListView: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        List {
            if store.data.hidden.isEmpty {
                Text("Nothing hidden. Use the ⋯ menu on an exercise during a workout to hide it.")
                    .foregroundStyle(Theme.sub)
                    .listRowBackground(Theme.row)
            }
            ForEach(store.data.hidden.sorted(), id: \.self) { id in
                HStack {
                    Text(Library.byID[id]?.name ?? id)
                    Spacer()
                    Button("Restore") { store.unhide(id) }
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .themedChipButton()
                }
                .listRowBackground(Theme.row)
            }
        }
        .scrollContentBackground(.hidden)
        .tabBarClearance()
        .background { SkyBackground(calm: true) }
        .navigationTitle("Hidden exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Section header that reads on any theme's background.
struct FormHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        if Theme.skin.isGlacier {
            Text(text)
        } else {
            Text(text)
                .font(Theme.label(13, .bold))
                .foregroundStyle(Theme.headSub)
        }
    }
}

/// Section footer that reads on any theme's background.
struct FormFooter: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        if Theme.skin.isGlacier {
            Text(text)
        } else {
            Text(text)
                .font(Theme.font(size: 13))
                .foregroundStyle(Theme.headSub)
        }
    }
}
