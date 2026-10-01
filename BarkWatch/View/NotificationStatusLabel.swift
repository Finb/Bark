//
//  NotificationStatusLabel.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI

struct NotificationStatusLabel: View {
    let state: NotificationState
    var onAddServer: (UUID) -> Void = { _ in }
    @State private var isSyncing = false

    private var isSyncDisabled: Bool {
        if case .registering = state.registrationState { return true }
        return isSyncing
    }

    var status: (title: LocalizedStringKey, tint: Color) {
        switch state.authorizationStatus {
        case nil:
            return ("Checking…", .secondary)
        case .notDetermined:
            return ("Not enabled", .orange)
        case .denied:
            return ("Disabled", .red)
        case .authorized, .provisional:
            switch state.registrationState {
            case .idle:
                return ("Not registered", .orange)
            case .registering:
                return ("Registering…", .green)
            case .registered:
                return state.authorizationStatus == .provisional
                    ? ("Delivered quietly", .green)
                    : ("Enabled", .green)
            case .failed:
                return ("Setup needed", .orange)
            }
        default:
            return ("Unavailable", .secondary)
        }
    }

    var body: some View {
        BigButtonView(
            caption: "Notifications",
            title: status.title,
            // Once notifications work, the only remaining step is adding a server.
            buttonColor: status.tint == .orange ? .orange : .secondary,
            message: state.authorizationStatus == .denied
                ? Text("On your iPhone, open Watch → My Watch → Notifications → Bark, then select Allow Notifications.")
                : nil
        ) {
            if state.authorizationStatus == .notDetermined {
                Button("Enable") {
                    Task { await state.enableNotifications() }
                }
                .disabled(state.isRequestingPermission)
            } else if state.isPushRegistrationReady {
                NavigationLink {
                    AddServerView(servers: state.servers, onAdd: onAddServer)
                } label: {
                    Image(systemName: "plus")
                }
            } else if state.hasNotificationPermission {
                Button {
                    isSyncing = true
                    Task {
                        defer { isSyncing = false }
                        await state.refreshAndRegister()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .disabled(isSyncDisabled)
            }
        }
        .containerBackground(status.tint.opacity(0.5).gradient, for: .tabView)
    }
}


#Preview("Checking") {
    ContentView(state: NotificationState())
}

#Preview("Permission needed") {
    let state = NotificationState()
    state.authorizationStatus = .notDetermined
    return ContentView(state: state)
}

#Preview("Disabled") {
    let state = NotificationState()
    state.authorizationStatus = .denied
    return ContentView(state: state)
}

#Preview("Not registered") {
    let state = NotificationState()
    state.authorizationStatus = .authorized
    state.registrationState = .idle
    return ContentView(state: state)
}

#Preview("Registering") {
    let state = NotificationState()
    state.authorizationStatus = .authorized
    state.registrationState = .registering
    return ContentView(state: state)
}
//
#Preview("Enabled") {
    let state = NotificationState()
    state.authorizationStatus = .authorized
    state.registrationState = .registered("preview-token")
    return ContentView(state: state)
}

#Preview("Delivered quietly") {
    let state = NotificationState()
    state.authorizationStatus = .provisional
    state.registrationState = .registered("preview-token")
    return ContentView(state: state)
}

#Preview("Setup needed") {
    let state = NotificationState()
    state.authorizationStatus = .authorized
    state.registrationState = .failed("Preview error")
    return ContentView(state: state)
}
