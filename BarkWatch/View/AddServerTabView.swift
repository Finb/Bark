//
//  AddServerTabView.swift
//  BarkWatch
//
//  Created by Jian Qin on 9/30/26.
//

import SwiftUI

/// Trailing tab for adding a server, laid out like `NotificationStatusLabel`.
struct AddServerTabView: View {
    let servers: BarkServers
    let onAdd: (UUID) -> Void

    var body: some View {
        BigButtonView(
            caption: servers.servers.isEmpty ? " " : "^[\(servers.servers.count) server](inflect: true) saved",
            title:"Add a Server",
            buttonColor: .secondary,
            message: servers.storageError.map { Text($0).font(.footnote).foregroundStyle(.red) }
        ) {
            NavigationLink {
                AddServerView(servers: servers, onAdd: onAdd)
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add server")
        }
        .containerBackground(Color.black, for: .tabView)
    }
}
