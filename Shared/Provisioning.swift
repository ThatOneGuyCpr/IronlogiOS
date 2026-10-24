import Foundation

/// Reads the provisioning profile SideStore embedded when it signed the app,
/// so we can see which entitlements were actually granted.
enum Provisioning {
    static let entitlements: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex)
        else { return [:] }
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let ents = plist["Entitlements"] as? [String: Any]
        else { return [:] }
        return ents
    }()

    static var found: Bool { !entitlements.isEmpty }

    static var appGroups: [String] {
        entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }

    static var hasHealthKit: Bool {
        entitlements["com.apple.developer.healthkit"] as? Bool ?? false
    }

    static var teamID: String? {
        entitlements["com.apple.developer.team-identifier"] as? String
    }

    /// Short, readable list of granted entitlement names.
    static var summary: String {
        guard found else { return "No embedded profile found" }
        return entitlements.keys
            .map { $0.replacingOccurrences(of: "com.apple.developer.", with: "")
                     .replacingOccurrences(of: "com.apple.security.", with: "") }
            .sorted()
            .joined(separator: ", ")
    }
}
