import SwiftUI

enum Theme {
    static let sky = Color(red: 0.33, green: 0.66, blue: 0.97)
    static let deep = Color(red: 0.09, green: 0.36, blue: 0.78)
    static let ink = Color(red: 0.06, green: 0.13, blue: 0.24)

    /// Soft sky gradient. Liquid Glass needs color behind it to read well.
    static var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.95, blue: 1.00),
                Color(red: 0.66, green: 0.84, blue: 0.99),
                Color(red: 0.82, green: 0.91, blue: 1.00),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
