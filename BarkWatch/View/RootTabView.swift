import SwiftUI

enum WatchTab: String {
    case permission
    case servers
    case history
}

struct RootTabView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("BarkWatch.selectedTab") private var storedTab = WatchTab.servers.rawValue
    @State private var selection: WatchTab = .servers

    var body: some View {
        Group {
            if model.permissionChecked {
                NavigationStack {
                    TabView(selection: $selection) {
                        if model.needsPermission {
                            PermissionView {
                                selection = .servers
                            }
                            .tag(WatchTab.permission)
                        }

                        ServerView()
                            .tag(WatchTab.servers)

                        HistoryView()
                            .tag(WatchTab.history)
                    }
                    .tabViewStyle(.verticalPage)
                }
            } else {
                ProgressView()
            }
        }
        .task { restoreSelection() }
        .onChange(of: model.permissionChecked) { _, _ in
            restoreSelection()
        }
        .onChange(of: model.needsPermission) { _, needsPermission in
            if needsPermission {
                selection = .permission
            } else if selection == .permission {
                selection = .servers
            }
        }
        .onChange(of: selection) { _, newValue in
            if newValue != .permission {
                storedTab = newValue.rawValue
            }
        }
    }

    private func restoreSelection() {
        guard model.permissionChecked else { return }

        if model.needsPermission {
            selection = .permission
        } else if selection == .permission {
            selection = .servers
        } else if let saved = WatchTab(rawValue: storedTab), saved != .permission {
            selection = saved
        }
    }
}
