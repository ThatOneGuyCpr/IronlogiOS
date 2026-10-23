import Foundation

/// Small key-value store shared between the app and the widget through an App Group.
///
/// Sideloaders like SideStore rename App Group IDs when they re-sign the app and
/// record the real ones under `ALTAppGroups` in Info.plist, so check there first.
enum SharedStore {
    static let fallbackGroup = "group.com.ironlog.shared"

    static var groupID: String {
        if let groups = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String],
           let first = groups.first {
            return first
        }
        return fallbackGroup
    }

    static var groupWorks: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) != nil
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    static func lastRoutine() -> RoutineID? {
        defaults.string(forKey: "lastRoutine").flatMap(RoutineID.init(rawValue:))
    }

    static func lastDate() -> Date? {
        defaults.object(forKey: "lastDate") as? Date
    }

    static func nextRoutine() -> RoutineID {
        RoutineID.next(after: lastRoutine())
    }

    static func complete(_ routine: RoutineID) {
        defaults.set(routine.rawValue, forKey: "lastRoutine")
        defaults.set(Date(), forKey: "lastDate")
    }

    static func openEquipment() -> Set<Equipment> {
        guard let raw = defaults.stringArray(forKey: "openEquipment") else {
            return Set(Equipment.allCases)
        }
        return Set(raw.compactMap(Equipment.init(rawValue:)))
    }

    static func saveOpen(_ open: Set<Equipment>) {
        defaults.set(open.map(\.rawValue), forKey: "openEquipment")
    }
}
