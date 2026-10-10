//
//  ServerPageView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI

/// One tab per saved server: address, key, encryption, and test delivery.
struct ServerTabView: View {
    let servers: ServerManager
    let id: UUID
    @State private var confirmsRemoval = false

    private var server: Server? { servers.servers.first { $0.id == id } }
    private var isBusy: Bool { servers.busyServerIDs.contains(id) }

    var body: some View {
        List {
            if let server {
                if let error = servers.errorMessages[id] {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
                Section("Address") {
                    if server.key.isEmpty {
                        Text(server.address.absoluteString).font(.caption)
                            .lineLimit(1)
                        Text("Registration needed").foregroundStyle(.secondary)
                    } else {
                        // Zero-width spaces let the URL wrap anywhere instead of being hyphenated.
                        Text((server.addressAndKey.absoluteString + "/").map(String.init).joined(separator: "\u{200B}"))
                            .font(.caption.monospaced())
                        Button("Send Test") {
                            Task { await servers.sendTestPush(serverID: id) }
                        }
                        .disabled(isBusy)
                    }
                }
                NavigationLink {
                    EncryptionView()
                } label: {
                    Label("Encryption", systemImage: "key.fill")
                }
                Button("Remove server", role: .destructive) {
                    confirmsRemoval = true
                }
                .confirmationDialog("Remove this server from the watch?", isPresented: $confirmsRemoval) {
                    Button("Remove server", role: .destructive) {
                        Task { await servers.removeServer(serverID: id) }
                    }
                }
            }
        }
        .navigationTitle(server?.address.host() ?? "Server")
        .containerBackground(Color.black, for: .tabView)
    }
}
