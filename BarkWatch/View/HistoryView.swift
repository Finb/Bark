import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var showingFilter = false
    @State private var showingClearOptions = false
    @State private var pendingRange: MessageDeleteTimeRange?
    @State private var showingClearConfirmation = false

    var body: some View {
        List {
            ForEach(model.messages.items, id: \.id) { message in
                NavigationLink {
                    MessageDetailView(message: message)
                } label: {
                    row(for: message)
                }
            }

            if model.messages.hasMore {
                ProgressView()
                    .onAppear {
                        model.messages.loadMore()
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingFilter = true
                } label: {
                    Image(systemName: filterIcon)
                }
                .accessibilityLabel("group")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingClearOptions = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("clear".localized)
            }
        }
        .sheet(isPresented: $showingClearOptions, onDismiss: {
            if pendingRange != nil {
                showingClearConfirmation = true
            }
        }) {
            ClearRangeListView { range in
                pendingRange = range
                showingClearOptions = false
            }
        }
        .confirmationDialog(
            Text(verbatim: "\(groupTitle): \(model.messages.filter.title)"),
            isPresented: $showingFilter,
            titleVisibility: .visible
        ) {
            ForEach(model.messages.groupFilters, id: \.self) { filter in
                Button {
                    model.messages.select(filter)
                } label: {
                    Text(verbatim: filter.title)
                }
            }
        }
        .alert(
            Text(verbatim: clearTitle),
            isPresented: $showingClearConfirmation,
            presenting: pendingRange
        ) { range in
            Button(role: .destructive) {
                model.messages.clear(range)
                pendingRange = nil
            } label: {
                Text(verbatim: "clear".localized)
            }
            Button(role: .cancel) {
                pendingRange = nil
            } label: {
                Text(verbatim: "Cancel".localized)
            }
        }
        .onAppear {
            model.messages.reload()
        }
    }

    private var clearTitle: String {
        guard let pendingRange else { return "" }
        return "\("clearFrom".localized)\n\(pendingRange.string)"
    }

    private var groupTitle: String {
        "group".localized
    }

    private var filterIcon: String {
        switch model.messages.filter {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .group:
            return "line.3.horizontal.decrease.circle.fill"
        }
    }

    private func row(for message: WatchMessage) -> some View {
        let title = message.title.flatMap { $0.isEmpty ? nil : $0 }
        let body = message.body.flatMap { $0.isEmpty ? nil : $0 }

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if model.messages.filter == .all, !message.group.isEmpty {
                    Text(verbatim: message.group)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(message.createDate, style: .relative)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if let title {
                Text(verbatim: title)
                    .font(.headline)
                    .lineLimit(1)
            }

            if let body {
                Text(verbatim: body)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct ClearRangeListView: View {
    let onSelect: (MessageDeleteTimeRange) -> Void

    @Environment(\.dismiss) private var dismiss

    private let primaryRanges: [MessageDeleteTimeRange] = [
        .lastHour, .today, .todayAndYesterday, .lastMonth, .allTime
    ]
    private let moreRanges: [MessageDeleteTimeRange] = [
        .beforeOneHour, .beforeToday, .beforeYesterday, .beforeOneMonth
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(primaryRanges, id: \.self) { range in
                        Button {
                            onSelect(range)
                        } label: {
                            Text(verbatim: range.string)
                        }
                    }
                } header: {
                    Text(verbatim: "clearFrom".localized)
                }

                Section {
                    ForEach(moreRanges, id: \.self) { range in
                        Button {
                            onSelect(range)
                        } label: {
                            Text(verbatim: range.string)
                        }
                    }
                } header: {
                    Text(verbatim: "more".localized)
                }
            }
            .navigationTitle(Text(verbatim: "clear".localized))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Cancel".localized)
                    }
                }
            }
        }
    }
}

private struct MessageDetailView: View {
    let message: WatchMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let title = message.title, !title.isEmpty {
                    Text(verbatim: title)
                        .font(.headline)
                }

                if let subtitle = message.subtitle, !subtitle.isEmpty {
                    Text(verbatim: subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text(message.createDate, style: .date)
                    Text(message.createDate, style: .time)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if !message.group.isEmpty {
                    Label(message.group, systemImage: "folder")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let body = message.body, !body.isEmpty {
                    Text(verbatim: body)
                        .font(.body)
                }

                if let image = message.image, let url = URL(string: image) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if phase.error == nil {
                            ProgressView()
                        }
                    }
                }

                if let link = message.url, let url = URL(string: link) {
                    Link(destination: url) {
                        Label(url.host ?? link, systemImage: "link")
                            .lineLimit(1)
                    }
                    .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension MessageFilter {
    var title: String {
        switch self {
        case .all:
            return "all".localized
        case .group(let group):
            return group.isEmpty ? "default".localized : group
        }
    }
}
