//
//  LastMessageView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//

import AuthenticationServices
import os
import SwiftUI
import UserNotifications
import WatchKit

/// Full-page card for the last received or opened message, laid out like
/// `BigButtonView`: a caption, a large title, the message, and an optional
/// rounded button for the link. Scrolls because message bodies can be long.
struct LastMessageView: View {
    let message: WatchMessage

    /// Tint follows the interruption level, like the status card follows its state.
    private var tint: Color {
        switch message.level {
        case .critical: .red
        case .timeSensitive: .orange
        case .active, .passive: .secondary
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    header
                    content
                    details
                    if let image = message.image {
                        AsyncImage(url: image) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 60)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Image")
                    }
                }
                .padding([.bottom, .horizontal], 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let url = message.url {
                    Link(destination: url) {
                        Text("Open Link")
                    }
                    .buttonStyle(LinkButtonStyle(tint: tint))
                    .padding([.horizontal, .bottom], 8)
                }
            }
        }
        .containerBackground(tint.gradient, for: .tabView)
        .modifier(WebBrowserSessionLinks())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Latest Notification")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .minimumScaleFactor(0.8)
            Text(message.title)
                .font(.system(.title3, design: .default, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
            if !message.subtitle.isEmpty {
                Text(message.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if let markdown = message.markdown, !markdown.isEmpty {
            WatchMarkdownView(source: markdown)
        } else {
            Text(message.body)
                .font(.body)
                .foregroundStyle(.white.opacity(message.body.isEmpty ? 0.6 : 0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !message.group.isEmpty {
                Label(message.group, systemImage: "folder")
            }
            Label(message.level.rawValue, systemImage: "bell")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

extension WebAuthenticationSession {
    /// watchOS can't open web pages through `Link` or `openURL` ("URL failed to load").
    /// A web authentication session is the only system browser available to apps.
    /// The callback scheme never fires; the person closes the page with Cancel,
    /// which ends the session with an error that is ignored.
    func browse(_ url: URL) async {
        Logger.links.debug("Opening browser session for \(url)")
        do {
            // Ephemeral: don't share cookies with other sessions.
            _ = try await authenticate(
                using: url,
                callbackURLScheme: "bark-watch-link",
                preferredBrowserSession: .ephemeral
            )
        } catch {
            // Cancel is the normal way to close the page; anything else is worth seeing.
            Logger.links.debug("Browser session ended: \(error)")
        }
    }
}

/// Opens web links in a browser session; other schemes are discarded.
private struct WebBrowserSessionLinks: ViewModifier {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    func body(content: Content) -> some View {
        content.environment(\.openURL, OpenURLAction { url in
            guard WatchNotification.validatedWebURL(url.absoluteString) != nil else { return .discarded }
            Task { await webAuthenticationSession.browse(url) }
            return .handled
        })
    }
}

private struct LinkButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .default, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(tint, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview {
    let content = UNMutableNotificationContent()
    content.title = "Server Alert"
    content.subtitle = "Production"
    content.body = "CPU usage exceeded 90% on web-01."
    content.threadIdentifier = "Monitoring"
    content.interruptionLevel = .critical

    return TabView {
        LastMessageView(message: WatchMessage(content: content))
    }
    .tabViewStyle(.verticalPage)
}
