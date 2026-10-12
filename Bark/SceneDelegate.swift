//
//  SceneDelegate.swift
//  Bark
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .black

        if UIDevice.current.userInterfaceIdiom == .pad {
            let splitViewController = BarkSplitViewController(style: .doubleColumn)
            window.rootViewController = BarkSnackbarController(rootViewController: splitViewController)
        } else {
            window.rootViewController = BarkSnackbarController(
                rootViewController: BarkTabBarController()
            )
        }

        self.window = window
        window.makeKeyAndVisible()

        if let url = connectionOptions.urlContexts.first?.url {
            handle(url: url)
        }
        if let response = connectionOptions.notificationResponse,
           response.actionIdentifier != UNNotificationDismissActionIdentifier
        {
            appDelegate?.handleNotification(
                userInfo: response.notification.request.content.userInfo
            )
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Setting -1 clears the badge without removing delivered notifications.
        UIApplication.shared.applicationIconBadgeNumber = -1

        Task {
            await appDelegate?.processPendingMessages()
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handle(url: url)
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        if handleWidgetDeepLink(url) {
            return true
        }

        if url.scheme?.lowercased() == "bark" && url.host?.lowercased() == "addserver" {
            // 提取参数
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let address = queryItems?.first(where: { $0.name == "address" })?.value

            // 处理添加服务器的逻辑
            if let serverAddress = try? address?.asURL() {
                let server = Server(address: serverAddress.absoluteString, key: "")
                ServerManager.shared.addServer(server: server)
                ServerManager.shared.setCurrentServer(serverId: server.id)
                ServerManager.shared.syncAllServers()
                HUDSuccess("AddedSuccessfully".localized)
            }
            return true
        }
        return false
    }

    private func handleWidgetDeepLink(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "bark", url.host?.lowercased() == "history" else {
            return false
        }

        Client.shared.currentTabPage = .messageHistory
        return true
    }
}
