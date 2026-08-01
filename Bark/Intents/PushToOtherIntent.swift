//
//  PushToOtherIntent.swift
//  Bark
//
//  Created by huangfeng on 2/21/25.
//  Copyright © 2025 Fin. All rights reserved.
//
import Alamofire
import AppIntents

@available(iOS 16, *)
struct PushToOtherIntent: AppIntent {
    static var title: LocalizedStringResource = "sendPushNotificationToOther"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "ServerAddress")
    var address: String
    
    @Parameter(title: "CustomedNotificationTitle")
    var title: String?
    @Parameter(title: "CustomedNotificationContent")
    var body: String?

    @Parameter(title: "ringtone")
    var isCall: Bool
    
    @Parameter(title: "criticalAlert")
    var isCritical: Bool
    
    @Parameter(title: "ringtoneVolume", optionsProvider: VolumeOptionsProvider())
    var volume: Int?
    
    @Parameter(title: "notificationSound", optionsProvider: SoundOptionsProvider())
    var sound: String?
    
    @Parameter(title: "notificationIcon")
    var icon: URL?
    
    @Parameter(title: "group")
    var group: String?

    @Parameter(title: "ttl")
    var ttl: Int?

    // default 参数类型是 Optional，简写成 .none 会被解析为 nil，即没有默认值，因此必须写全枚举名
    @Parameter(title: "encryptionSuite", default: PushEncryptionSuite.none)
    var encryptionSuite: PushEncryptionSuite

    @Parameter(title: "encryptionKey", description: "encryptionKeyDescription")
    var encryptionKey: String?

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let address = URL(string: address) else {
            throw "Invalid URL"
        }
        
        var params: [String: Any] = [:]
        
        if let title, !title.isEmpty {
            params["title"] = title.urlDecoded()
        }
        if let body, !body.isEmpty {
            params["body"] = body.urlDecoded()
        }
        if title == nil, body == nil {
            params["body"] = "Empty Notification"
        }
        if isCritical {
            params["level"] = "critical"
        }
        if let volume {
            params["volume"] = volume
        }
        if isCall {
            params["call"] = 1
        }
        if let sound, !sound.isEmpty {
            params["sound"] = sound
        }
        if let icon {
            params["icon"] = icon.absoluteString
        }
        if let group, !group.isEmpty {
            params["group"] = group
        }
        if let ttl {
            params["ttl"] = ttl
        }

        switch encryptionSuite {
        case .none:
            // 明文发送。填了密钥说明用户本意是加密，此时静默发明文是最坏的结果
            if let encryptionKey, !encryptionKey.isEmpty {
                throw "encryptionSuiteRequiredForKey".localized
            }
        case .aesGCM:
            guard let encryptionKey, !encryptionKey.isEmpty else {
                throw "encryptionKeyRequired".localized
            }
            params = try EncryptedPushParams.requestParams(params: params, encryptionKey: encryptionKey)
        }

        let response = await AF.request(address, method: .post, parameters: params, encoding: JSONEncoding.default)
            .serializingDecodable(PushResponse.self)
            .response
        
        // 打印返回的body
        if response.response?.statusCode != 200 {
            return .result(value: false)
        }
        return .result(value: true)
    }
}
