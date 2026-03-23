//
//  WatchMessageDetailView.swift
//  BarkWatch Watch App Extension
//
//  Created by Codex on 2026/3/22.
//

import SwiftUI

struct WatchMessageDetailView: View {
    let message: BarkWatchMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(message.displayTitle)
                    .font(.headline)

                Text(message.formattedTime)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(message.body.isEmpty ? "-" : message.body)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Detail")
    }
}
