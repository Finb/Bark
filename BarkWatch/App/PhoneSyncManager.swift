import Foundation
import WatchConnectivity

final class PhoneSyncManager: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = PhoneSyncManager()

    private enum Key {
        static let type = "type"
        static let payload = "payload"
    }

    enum SyncError: Error {
        case unavailable
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func requestData(for request: WatchSyncRequest) async throws -> Data? {
        let session = WCSession.default
        guard session.activationState == .activated else {
            throw SyncError.unavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(
                [Key.type: request.rawValue],
                replyHandler: { reply in
                    guard reply[Key.type] as? String == request.rawValue else {
                        continuation.resume(throwing: SyncError.unavailable)
                        return
                    }
                    continuation.resume(returning: reply[Key.payload] as? Data)
                },
                errorHandler: { _ in
                    continuation.resume(throwing: SyncError.unavailable)
                }
            )
        }
    }

    func copyAddressAndKeyToPhone(_ value: String, completion: @escaping (Bool) -> Void) {
        let session = WCSession.default
        guard !value.isEmpty,
              session.activationState == .activated
        else {
            completion(false)
            return
        }

        session.sendMessage([
            Key.type: WatchSyncAction.copyAddressAndKey.rawValue,
            Key.payload: value
        ], replyHandler: { reply in
            completion((reply[Key.type] as? String) == WatchSyncAction.copyAddressAndKey.rawValue)
        }, errorHandler: { _ in
            completion(false)
        })
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}
