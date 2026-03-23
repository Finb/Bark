//
//  WatchMessageListView.swift
//  BarkWatch Watch App Extension
//
//  Created by Codex on 2026/3/22.
//

import SwiftUI

struct WatchMessageListView: View {
    @EnvironmentObject private var sessionManager: BarkWatchSessionManager

    var body: some View {
        NavigationStack {
            List {
                if sessionManager.messages.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "bell.slash")
                                .font(.title3)
                            Text("No Messages")
                                .font(.headline)
                            Text(sessionManager.syncStatus)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    Section {
                        Text(sessionManager.syncStatus)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Section("Recent 20") {
                        ForEach(sessionManager.messages) { message in
                            NavigationLink(value: message) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.displayTitle)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(message.body)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                    Text(message.formattedTime)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.carousel)
            .navigationDestination(for: BarkWatchMessage.self) { message in
                WatchMessageDetailView(message: message)
            }
            .navigationTitle("Bark")
        }
    }
}

extension BarkWatchMessage {
    var displayTitle: String {
        if title.isEmpty {
            return "Untitled"
        }
        return title
    }

    var formattedTime: String {
        Self.dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
