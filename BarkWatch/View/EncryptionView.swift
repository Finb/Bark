//
//  EncryptionView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI

struct EncryptionView: View {
    @State private var algorithm = Algorithm.aes256.rawValue
    @State private var mode = "GCM"
    @State private var padding = "noPadding"
    @State private var key = ""
    @State private var error: String?
    @State private var saved: CryptoSettingFields?

    private var paddings: [String] { mode == "GCM" ? ["noPadding"] : ["noPadding", "pkcs7"] }

    var body: some View {
        Form {
            Picker("Algorithm", selection: $algorithm) {
                ForEach(Algorithm.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
            }
            Picker("Mode", selection: $mode) {
                ForEach(Algorithm(rawValue: algorithm)?.modes ?? [], id: \.self) { Text($0).tag($0) }
            }
            Picker("Padding", selection: $padding) {
                ForEach(paddings, id: \.self) { Text($0).tag($0) }
            }
            Section {
                TextFieldLink(prompt: Text("Key")) {
                    if key.isEmpty {
                        Text("Key").foregroundStyle(.secondary)
                    } else {
                        // Zero-width spaces let the key wrap between any two characters
                        // instead of being truncated or hyphenated.
                        Text(key.map(String.init).joined(separator: "\u{200B}"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } onSubmit: { key = $0 }
                Button("Generate key") {
                    do {
                        key = try WatchEncryption.randomText(length: Algorithm(rawValue: algorithm)?.keyLength ?? 32)
                    } catch { self.error = error.localizedDescription }
                }
            } footer: {
                if let error { Text(error).foregroundStyle(.red) }
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .navigationTitle("Encryption")
        .onChange(of: mode) {
            // GCM only supports noPadding.
            if !paddings.contains(padding) { padding = "noPadding" }
        }
        .onChange(of: [algorithm, mode, padding, key]) { save() }
        .task {
            do {
                if let fields = try WatchCryptoStore.load() {
                    var loaded = fields
                    loaded.iv = nil
                    saved = loaded
                    algorithm = fields.algorithm
                    mode = fields.mode
                    padding = fields.padding
                    key = fields.key ?? ""
                }
            } catch { self.error = error.localizedDescription }
        }
    }

    /// Saves the settings whenever they change. An empty key removes the saved settings;
    /// an invalid combination is reported but not saved.
    private func save() {
        let fields = key.isEmpty ? nil : CryptoSettingFields(algorithm: algorithm, mode: mode,
            padding: padding, key: key, iv: nil)
        // Skip the change events caused by loading the saved settings.
        guard fields != saved else { return }
        error = nil
        do {
            try WatchCryptoStore.save(fields)
            saved = fields
        } catch { self.error = error.localizedDescription }
    }
}
