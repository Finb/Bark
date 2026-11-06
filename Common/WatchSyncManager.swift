import Foundation
import UIKit
import WatchConnectivity

final class WatchSyncManager: NSObject {
    static let shared = WatchSyncManager()

    private enum Key {
        static let type = "type"
        static let payload = "payload"
    }

    private var pendingCopy: String?

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

    func copyPendingIfNeeded() {
        guard let value = pendingCopy else { return }
        pendingCopy = nil
        UIPasteboard.general.string = value
        HUDSuccess("Copy".localized)
    }

    private func handleCopyAction(_ message: [String: Any]) -> Bool {
        guard WatchSyncAction(rawValue: message[Key.type] as? String ?? "") == .copyAddressAndKey,
              let value = message[Key.payload] as? String,
              !value.isEmpty
        else { return false }

        dispatch_sync_safely_main_queue {
            if UIApplication.shared.applicationState == .background {
                self.pendingCopy = value
            } else {
                UIPasteboard.general.string = value
                HUDSuccess("Copy".localized)
            }
        }
        return true
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
        if handleCopyAction(message) {
            replyHandler([Key.type: WatchSyncAction.copyAddressAndKey.rawValue])
            return
        }

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
