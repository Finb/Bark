import SwiftUI

struct EncryptionView: View {
    @Environment(\.dismiss) private var dismiss

    private let algorithms: [Algorithm] = [.aes128, .aes192, .aes256]
    private let paddingLabel = "Padding"

    @State private var algorithm: Algorithm = .aes256
    @State private var mode = "GCM"
    @State private var padding = "noPadding"
    @State private var key = ""
    @State private var errorMessage: String?
    @State private var isSyncing = false
    @State private var syncFailed = false

    var body: some View {
        Form {
            Picker("algorithm", selection: $algorithm) {
                ForEach(algorithms, id: \.self) { algorithm in
                    Text(verbatim: algorithm.rawValue)
                }
            }
            .onChange(of: algorithm) { _, newValue in
                if !newValue.modes.contains(mode) {
                    mode = newValue.modes[0]
                    padding = padding(for: mode)
                }
            }

            Picker("mode", selection: $mode) {
                ForEach(algorithm.modes, id: \.self) { mode in
                    Text(verbatim: mode)
                }
            }
            .onChange(of: mode) { _, newValue in
                padding = padding(for: newValue)
            }

            LabeledContent(paddingLabel, value: padding)

            TextField("enterKey".localized(with: algorithm.keyLength), text: $key)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Section {
                Button(action: sync) {
                    HStack(spacing: 4) {
                        Label("syncFromIPhone", systemImage: "arrow.down.circle")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        if isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)
            }
        }
        .navigationTitle("encryptionSettings")
        .alert("syncFromIPhoneFailed", isPresented: $syncFailed) {
            Button("confirm", role: .cancel) {}
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: save) {
                    Image(systemName: "checkmark")
                }
                .disabled(!isValid)
            }
        }
        .onAppear(perform: load)
    }

    private var isValid: Bool {
        key.isEmpty || key.count == algorithm.keyLength
    }

    private func padding(for mode: String) -> String {
        mode == "GCM" ? "noPadding" : "pkcs7"
    }

    private func load() {
        guard let fields = CryptoSettingManager.shared.fields,
              let storedAlgorithm = Algorithm(rawValue: fields.algorithm)
        else {
            return
        }

        algorithm = storedAlgorithm
        mode = storedAlgorithm.modes.contains(fields.mode) ? fields.mode : storedAlgorithm.modes[0]
        padding = padding(for: mode)
        key = fields.key ?? ""
    }

    private func save() {
        if key.isEmpty {
            CryptoSettingManager.shared.fields = nil
            dismiss()
            return
        }

        let fields = CryptoSettingFields(
            algorithm: algorithm.rawValue,
            mode: mode,
            padding: padding,
            key: key,
            iv: currentIv
        )

        do {
            try AESCryptoModel.validate(cryptoFields: fields)
            CryptoSettingManager.shared.fields = fields
            dismiss()
        } catch {
            errorMessage = error.rawString()
        }
    }

    private var currentIv: String? {
        guard let iv = CryptoSettingManager.shared.fields?.iv else {
            return nil
        }
        let expected = ["CBC": 16, "GCM": 12][mode] ?? 0
        return iv.count == expected ? iv : nil
    }

    private func sync() {
        guard !isSyncing else { return }
        isSyncing = true
        errorMessage = nil

        Task {
            defer { isSyncing = false }

            do {
                guard let data = try await PhoneSyncManager.shared.requestData(for: .cryptoSetting),
                      let fields = try? JSONDecoder().decode(CryptoSettingFields.self, from: data),
                      let storedAlgorithm = Algorithm(rawValue: fields.algorithm)
                else {
                    syncFailed = true
                    return
                }

                algorithm = storedAlgorithm
                mode = storedAlgorithm.modes.contains(fields.mode) ? fields.mode : storedAlgorithm.modes[0]
                padding = fields.padding
                key = fields.key ?? ""
                CryptoSettingManager.shared.fields = fields
            } catch {
                syncFailed = true
            }
        }
    }
}
