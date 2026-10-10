//
//  AddServerView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI

struct AddServerView: View {
    let servers: ServerManager
    var onAdd: (UUID) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @State private var address = "https://"
    @State private var error: String?
    @State private var isAdding = false

    var body: some View {
        Form {
            TextField("Server address", text: $address)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(addServer)
                .disabled(isAdding)
            if let error {
                Text(error).foregroundStyle(.red)
            }
            Text("Use a custom server. The public Bark service cannot send to this app.")
                .font(.footnote)
        }
        .navigationTitle("Add server")
    }

    private func addServer() {
        guard !isAdding else { return }
        error = nil

        do {
            let id = try servers.addServer(address: address)
            isAdding = true
            Task {
                await servers.register(serverID: id)
                isAdding = false

                if let registrationError = servers.errorMessages[id] {
                    error = registrationError
                    await servers.removeServer(serverID: id)
                } else {
                    onAdd(id)
                    dismiss()
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
