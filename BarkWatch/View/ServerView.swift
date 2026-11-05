import SwiftUI

struct ServerView: View {
    @Environment(AppModel.self) private var model

    private var server: Server? {
        model.servers.currentServer
    }

    private var hasKey: Bool {
        server?.key.isEmpty == false
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: hasKey ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(hasKey ? Color.green : Color.orange)

                        Text(verbatim: server?.displayName ?? defaultServer)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    Text(verbatim: server?.cleanAddress ?? defaultServer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(verbatim: hasKey ? (server?.key ?? "") : "deviceNotRegistered".localized)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(hasKey ? Color.primary : Color.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.vertical, 4)
                
                Button(action: sendTest) {
                    HStack(spacing: 4) {
                        Label("sendTest", systemImage: "paperplane.fill")
                        Spacer(minLength: 0)
                        if model.servers.isSending {
                            ProgressView()
                        }
                    }
                }
                .disabled(!hasKey || model.servers.isSending)

                if let result = model.servers.testResult {
                    switch result {
                    case .sent:
                        Text("testPushSent")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    case .failed(let message):
                        Text(verbatim: message)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                NavigationLink {
                    ServerListView()
                } label: {
                    Label("serverList", systemImage: "server.rack")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                NavigationLink {
                    EncryptionView()
                } label: {
                    Label("encryptionSettings", systemImage: "key.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .onAppear {
            model.servers.reload()
            model.servers.resetTestResult()
        }
    }

    private func sendTest() {
        guard let server else { return }
        Task { await model.servers.sendTest(server: server) }
    }
}
