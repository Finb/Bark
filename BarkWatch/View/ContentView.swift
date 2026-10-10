//
//  ContentView.swift
//  BarkWatch
//
//  Created by Jian Qin on 9/30/26.
//

import AuthenticationServices
import os
import SwiftUI

struct ContentView: View {
    let state: NotificationState
    @State private var selection: Tab = .status
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.scenePhase) private var scenePhase

    private enum Tab: Hashable {
        case status, lastMessage, server(UUID), add
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                if state.needsNotificationSetup {
                    NotificationStatusTab(state: state) { selection = .server($0) }
                        .tag(Tab.status)
                }

                if let message = state.lastMessage {
                    LastMessageView(message: message)
                        .tag(Tab.lastMessage)
                }
                
                ForEach(state.servers.servers) { server in
                    ServerTabView(servers: state.servers, id: server.id)
                        .tag(Tab.server(server.id))
                }

                // The status page offers adding the first server; this page appears afterwards.
                if !state.servers.servers.isEmpty {
                    AddServerTabView(servers: state.servers) { selection = .server($0) }
                        .tag(Tab.add)
                }

            }
            .tabViewStyle(.verticalPage)
        }
        // A link tapped in the notification interface launches the app; show the
        // message it came from and open the link in a browser session.
        // `initial` covers a cold launch, where the link is set before this view exists.
        .onChange(of: state.pendingBrowserURL, initial: true) { openPendingLink() }
        .onChange(of: scenePhase) { openPendingLink() }
        .onChange(of: state.lastMessage == nil) { _, isEmpty in
            guard isEmpty, selection == .lastMessage else { return }
            selection = state.needsNotificationSetup ? .status :
                state.servers.servers.first.map { .server($0.id) } ?? .add
        }
        // Tapping the complication shows the message it displays.
        .onOpenURL { url in
            guard url.host() == WatchArchive.messageURLHost else { return }
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "id" }?.value
            if state.showArchivedMessage(id: id) { selection = .lastMessage }
        }
    }

    /// Opens a link tapped in the notification interface. Waits for the app to be
    /// active: presenting the browser while the app is still launching from the
    /// notification leaves it stuck and unresponsive.
    private func openPendingLink() {
        Logger.links.debug("Pending link: \(state.pendingBrowserURL?.absoluteString ?? "none"), scene phase: \(String(describing: scenePhase))")
        guard let url = state.pendingBrowserURL, scenePhase == .active else { return }
        state.pendingBrowserURL = nil
        selection = .lastMessage
        Task { @MainActor in
            await webAuthenticationSession.browse(url)
        }
    }
}
