import Foundation
import WatchConnectivity

/// Reports whether the Watch app made it onto the watch. Messaging comes later.
final class WatchLink: NSObject, ObservableObject, WCSessionDelegate {
    @Published var status = "Checking..."

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            status = "Watch connectivity not supported"
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let text: String
        if let error {
            text = "Error: \(error.localizedDescription)"
        } else if !session.isPaired {
            text = "No paired watch"
        } else if session.isWatchAppInstalled {
            text = "Watch app installed"
        } else {
            text = "Watch paired, app not installed"
        }
        DispatchQueue.main.async { self.status = text }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
