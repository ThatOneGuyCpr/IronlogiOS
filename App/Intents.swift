import AppIntents
import UniformTypeIdentifiers

/// Shortcuts action that returns a backup file, so an automation can save it to iCloud Drive.
struct ExportBackupIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Ironlog Backup"
    static var description = IntentDescription(
        "Gets a backup of your Ironlog workouts and settings. Follow it with Save File to keep a copy in iCloud Drive."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard let data = Store.backupData() else { throw BackupError.unreadable }
        let file = IntentFile(data: data, filename: "Ironlog-backup.json", type: .json)
        return .result(value: file)
    }
}

enum BackupError: Error, CustomLocalizedStringResourceConvertible {
    case unreadable

    var localizedStringResource: LocalizedStringResource {
        "Ironlog couldn't read its saved data."
    }
}

struct IronlogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExportBackupIntent(),
            phrases: ["Back up \(.applicationName)"],
            shortTitle: "Back Up Ironlog",
            systemImageName: "externaldrive.fill"
        )
    }
}
