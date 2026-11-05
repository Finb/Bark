import SwiftUI

struct PermissionView: View {
    @Environment(AppModel.self) private var model
    var onGranted: () -> Void

    @State private var requesting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)

                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if canRequest {
                    Button(action: request) {
                        Text("goToSettings")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(requesting)
                } else {
                    Text("permissionGuide")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
    }

    private var notificationsMissing: Bool {
        !model.notificationsAllowed
    }

    private var canRequest: Bool {
        model.authorizationStatus == .notDetermined
    }

    private var title: LocalizedStringKey {
        notificationsMissing ? "notificationPermissionOff" : "criticalAlertPermissionOff"
    }

    private var detail: LocalizedStringKey {
        notificationsMissing ? "notificationPermissionOffDetail" : "criticalAlertPermissionOffDetail"
    }

    private var iconName: String {
        notificationsMissing ? "bell.badge.fill" : "exclamationmark.triangle.fill"
    }

    private func request() {
        requesting = true
        Task {
            await model.requestAuthorization()
            await model.refresh()
            requesting = false

            if !model.needsPermission {
                onGranted()
            }
        }
    }
}
