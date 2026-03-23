//
//  BarkWatch_Watch_AppApp.swift
//  BarkWatch Watch App Extension
//
//  Created by Codex on 2026/3/22.
//

import SwiftUI

@main
struct BarkWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = BarkWatchSessionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchMessageListView()
                .environmentObject(sessionManager)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                sessionManager.requestSync()
            }
        }
    }
}
