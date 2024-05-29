//
//  IconProcessor.swift
//  NotificationServiceExtension
//
//  Created by huangfeng on 2024/5/29.
//  Copyright © 2024 Fin. All rights reserved.
//

import Foundation
import Intents

class IconProcessor: NotificationContentProcessor {
    func process(content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        if #available(iOSApplicationExtension 15.0, *) {
            let userInfo = bestAttemptContent.userInfo
            
            guard let imageUrl = userInfo["icon"] as? String,
                  let imageFileUrl = await ImageDownloader.downloadImage(imageUrl)
            else {
                return bestAttemptContent
            }
            
            var personNameComponents = PersonNameComponents()
            personNameComponents.nickname = bestAttemptContent.title
            
            let avatar = INImage(imageData: NSData(contentsOfFile: imageFileUrl)! as Data)
            let senderPerson = INPerson(
                personHandle: INPersonHandle(value: "", type: .unknown),
                nameComponents: personNameComponents,
                displayName: personNameComponents.nickname,
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .none
            )
            let mePerson = INPerson(
                personHandle: INPersonHandle(value: "", type: .unknown),
                nameComponents: nil,
                displayName: nil,
                image: nil,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: true,
                suggestionType: .none
            )
            
            let intent = INSendMessageIntent(
                recipients: [mePerson],
                outgoingMessageType: .outgoingMessageText,
                content: bestAttemptContent.body,
                speakableGroupName: INSpeakableString(spokenPhrase: personNameComponents.nickname ?? ""),
                conversationIdentifier: bestAttemptContent.threadIdentifier,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
            
            intent.setImage(avatar, forParameterNamed: \.sender)
            
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            
            do {
                try await interaction.donate()
                let content = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                return content
            } catch {
                return bestAttemptContent
            }
        } else {
            return bestAttemptContent
        }
    }
}
