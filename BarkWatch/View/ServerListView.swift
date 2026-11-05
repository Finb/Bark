import SwiftUI

struct ServerListView: View {
    @Environment(AppModel.self) private var model
    @State private var addingServer = false

    var body: some View {
        List {
            ForEach(model.servers.servers, id: \.id) { server in
                NavigationLink {
                    ServerDetailView(server: server)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(verbatim: server.displayName)
                                .font(.headline)
                                .lineLimit(1)
                            if server.id == model.servers.currentServer?.id {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.tint)
                            }
                        }
                        Text(verbatim: server.cleanAddress)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Section {
                Button {
                    Task { await model.servers.syncServers(deviceToken: model.deviceToken) }
                } label: {
                    HStack(spacing: 4) {
                        Label("syncFromIPhone", systemImage: "arrow.down.circle")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        if model.servers.isSyncingServers {
                            ProgressView()
                        }
                    }
                }
                .disabled(model.servers.isSyncingServers)
            }
        }
        .navigationTitle("serverList")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addingServer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert(
            "syncFromIPhoneFailed",
            isPresented: Binding(
                get: { model.servers.syncServersFailed },
                set: { model.servers.syncServersFailed = $0 }
            )
        ) {
            Button("confirm", role: .cancel) {}
        }
        .sheet(isPresented: $addingServer) {
            AddServerView()
        }
        .onAppear {
            model.servers.reload()
        }
    }
}

private struct ServerDetailView: View {
    let server: Server

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingDelete = false

    private var isCurrent: Bool {
        server.id == model.servers.currentServer?.id
    }

    var body: some View {
        List {
            Section {
                Text(verbatim: server.cleanAddress)
                    .font(.footnote)
                Text(verbatim: server.key.isEmpty ? "deviceNotRegistered".localized : server.key)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(server.key.isEmpty ? .secondary : .primary)
            }

            if !isCurrent {
                Button("setAsDefaultServer") {
                    model.servers.setCurrent(server)
                    dismiss()
                }
            }

            Button("deleteServer", role: .destructive) {
                confirmingDelete = true
            }
            .disabled(model.servers.servers.count <= 1)
        }
        .navigationTitle(server.displayName)
        .confirmationDialog("confirmDeleteServer", isPresented: $confirmingDelete) {
            Button("deleteServer", role: .destructive) {
                model.servers.remove(server, deviceToken: model.deviceToken)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct AddServerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let addressPlaceholder = "https://"

    @State private var address = "https://"
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                TextField(addressPlaceholder, text: $address)

                if failed {
                    Text("InvalidServer")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                Button("AddServer") {
                    if model.servers.addServer(address: address, deviceToken: model.deviceToken) {
                        dismiss()
                    } else {
                        failed = true
                    }
                }
                .disabled(address.count <= 8)
            }
            .navigationTitle("AddServer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
