//
//  HomeViewController.swift
//  Bark
//

import Material
import RxCocoa
import RxSwift
import UIKit
import UserNotifications

class HomeViewController: BaseViewController<HomeViewModel> {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 32, right: 0)
        return scrollView
    }()
    private let contentStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    private let contentView = UIView()

    private let permissionCard = HomePermissionCard()
    private let exampleCard = HomeExampleCard()
    private let settingsCard = HomeSettingsCard()
    private let documentsCard = HomeDocumentsCard()
    private let exampleTypeRelay = PublishRelay<HomeViewModel.ExampleType>()
    private let testExampleRelay = PublishRelay<HomeViewModel.ExampleType>()

    private let newButton: BKButton = {
        let btn = BKButton()
        btn.setImage(Icon.add, for: .normal)
        btn.imageView?.tintColor = BKColor.grey.darken4
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.accessibilityLabel = "AddServer".localized
        return btn
    }()

    override func makeUI() {
        setupNavigation()
        setupHierarchy()
        bindActions()
        bindTabSelection()
        bindAppLifecycle()
    }

    private func setupNavigation() {
        navigationItem.setBarButtonItems(items: [
            UIBarButtonItem(customView: newButton)
        ], position: .right)
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalTo(self.view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.width.lessThanOrEqualTo(680)
            make.width.equalTo(contentView.snp.width).offset(-32).priority(.high)
            make.centerX.equalToSuperview()
        }

        [permissionCard, exampleCard, settingsCard, documentsCard].forEach(contentStack.addArrangedSubview)
        // 等异步取到权限状态、configure 后再显示，避免闪出一张空卡片
        permissionCard.isHidden = true
    }

    private func bindActions() {
        newButton.addTarget(self, action: #selector(addServer), for: .touchUpInside)
        permissionCard.button.addTarget(self, action: #selector(enableNotifications), for: .touchUpInside)
        exampleCard.segmentedControl.addTarget(self, action: #selector(updateExample), for: .valueChanged)
        exampleCard.copyButton.addTarget(self, action: #selector(copyExample), for: .touchUpInside)
        exampleCard.testButton.addTarget(self, action: #selector(testExample), for: .touchUpInside)
        settingsCard.serverRow.addTarget(self, action: #selector(openServerList), for: .touchUpInside)
        settingsCard.cryptoRow.addTarget(self, action: #selector(openEncryptionSettings), for: .touchUpInside)
        settingsCard.soundsRow.addTarget(self, action: #selector(openSounds), for: .touchUpInside)
        documentsCard.parameterButton.addTarget(self, action: #selector(openDocumentation), for: .touchUpInside)
        documentsCard.faqButton.addTarget(self, action: #selector(openFAQ), for: .touchUpInside)
    }

    private func bindTabSelection() {
        Client.shared.currentTabBarController?
            .tabBarItemDidClick
            .filter { $0 == .service }
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.scrollView.setContentOffset(CGPoint(x: 0, y: -self.scrollView.adjustedContentInset.top), animated: true)
            }).disposed(by: rx.disposeBag)
    }

    private func bindAppLifecycle() {
        // 从系统设置返回时刷新权限状态
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshNotificationPermission()
            }).disposed(by: rx.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshNotificationPermission()
    }

    override func bindViewModel() {
        let output = viewModel.transform(input: HomeViewModel.Input(
            exampleType: exampleTypeRelay.asDriver(onErrorDriveWith: .empty()),
            testExample: testExampleRelay.asDriver(onErrorDriveWith: .empty())
        ))

        output.title.drive(navigationItem.rx.title).disposed(by: rx.disposeBag)
        output.exampleText.drive(onNext: { [weak self] text in
            self?.exampleCard.codeText = text
        }).disposed(by: rx.disposeBag)
        output.showSnackbar.drive(onNext: { [weak self] text in
            self?.showSnackbar(text: text)
        }).disposed(by: rx.disposeBag)
    }

    private func refreshNotificationPermission() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            self.permissionCard.configure(type: self.permissionCardType(for: settings))
            self.permissionCard.isHidden = false
        }
    }

    private func permissionCardType(for settings: UNNotificationSettings) -> PermissionCardType {
        if !hasNotificationPermission(settings.authorizationStatus) {
            return .notification
        }
        if settings.criticalAlertSetting == .disabled {
            return .criticalAlert
        }
        return .granted
    }

    private func hasNotificationPermission(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    @objc private func enableNotifications() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .denied || settings.criticalAlertSetting == .disabled {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
                return
            }

            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])) ?? false
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            self.refreshNotificationPermission()
        }
    }

    @objc private func updateExample() {
        guard let type = HomeViewModel.ExampleType(rawValue: exampleCard.segmentedControl.selectedIndex) else { return }
        exampleTypeRelay.accept(type)
    }

    @objc private func copyExample() {
        UIPasteboard.general.string = exampleCard.codeText
        showSnackbar(text: "Copy".localized)
    }

    @objc private func testExample() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard self.hasNotificationPermission(settings.authorizationStatus) else {
                self.presentPermissionAlert()
                return
            }
            guard let type = HomeViewModel.ExampleType(rawValue: self.exampleCard.segmentedControl.selectedIndex) else { return }
            self.testExampleRelay.accept(type)
        }
    }

    private func presentPermissionAlert() {
        let alert = UIAlertController(title: "notificationPermissionOff".localized, message: "notificationPermissionAlertMessage".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "goToSettings".localized, style: .default) { [weak self] _ in
            self?.enableNotifications()
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        present(alert, animated: true)
    }

    @objc private func openEncryptionSettings() {
        presentInNavigation(CryptoSettingController(viewModel: CryptoSettingViewModel()))
    }

    @objc private func openSounds() {
        presentInNavigation(SoundsViewController(viewModel: SoundsViewModel()))
    }

    @objc private func addServer() {
        navigationController?.pushViewController(NewServerViewController(viewModel: NewServerViewModel()), animated: true)
    }

    @objc private func openDocumentation() {
        openWebPage("docUrl".localized)
    }

    @objc private func openFAQ() {
        openWebPage("faqUrl".localized)
    }

    private func openWebPage(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        navigationController?.present(BarkSFSafariViewController(url: url), animated: true)
    }

    private func presentInNavigation(_ controller: UIViewController) {
        navigationController?.present(BarkNavigationController(rootViewController: controller), animated: true)
    }

    @objc private func openServerList() {
        let controller = BarkSnackbarController(rootViewController: BarkNavigationController(rootViewController: ServerListViewController(viewModel: ServerListViewModel())))
        navigationController?.present(controller, animated: true)
    }
}
