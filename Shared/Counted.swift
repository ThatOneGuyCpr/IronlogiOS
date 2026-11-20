import Foundation

extension Int {
    /// "1 set", "2 sets". Pass the plural when it isn't just an added "s".
    func counted(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) " + (self == 1 ? singular : (plural ?? singular + "s"))
    }
}
