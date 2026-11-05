import Foundation
import WatchConnectivity

final class WatchSyncManager: NSObject {
    static let shared = WatchSyncManager()

    private enum Key {
        static let type = "type"
        static let payload = "payload"
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func payload(for request: WatchSyncRequest) -> Data? {
        switch request {
        case .cryptoSetting:
            return CryptoSettingManager.shared.fields.flatMap { try? JSONEncoder().encode($0) }
        case .serverList:
            return try? JSONEncoder().encode(ServerManager.shared.servers.map(\.cleanAddress))
        }
    }
}

extension WatchSyncManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let rawValue = message[Key.type] as? String,
              let request = WatchSyncRequest(rawValue: rawValue)
        else {
            replyHandler([:])
            return
        }

        var reply: [String: Any] = [Key.type: request.rawValue]
        reply[Key.payload] = payload(for: request)
        replyHandler(reply)
    }
}
