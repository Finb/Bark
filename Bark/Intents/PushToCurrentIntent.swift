//
//  Intents.swift
//  Bark
//
//  Created by huangfeng on 2/20/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import Alamofire
import AppIntents

@available(iOS 16, *)
struct PushToCurrentIntent: AppIntent {
    static var title: LocalizedStringResource = "sendPushNotification"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "ServerAddress", optionsProvider: ServerAddressOptionsProvider())
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
