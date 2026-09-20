//
//  HomeViewModel.swift
//  Bark
//

import Foundation
import RxCocoa
import RxSwift

class HomeViewModel: ViewModel, ViewModelType {
    enum ExampleType: Int {
        case get
        case post
        case json
    }

    // 示例文本和测试推送共用的参数，避免两边不一致
    private enum ExampleParams {
        static let title = "title"
        static let body = "body"
        static let group = "example"
        static let ttl = 600
    }

    struct Input {
        let exampleType: Driver<ExampleType>
        let testExample: Driver<ExampleType>
    }

    struct Output {
        let title: Driver<String>
        let exampleText: Driver<String>
        let showSnackbar: Driver<String>
    }

    func transform(input: Input) -> Output {
        let title = BehaviorRelay(value: ServerManager.shared.currentServer.displayName)
        let selectedExample = BehaviorRelay(value: ExampleType.get)
        let exampleText = BehaviorRelay(value: makeExampleText(for: .get))
        let showSnackbar = PublishRelay<String>()

        input.exampleType.drive(onNext: { [weak self] type in
            guard let self else { return }
            selectedExample.accept(type)
            exampleText.accept(self.makeExampleText(for: type))
        }).disposed(by: rx.disposeBag)

        ServerManager.shared.currentServerUpdateRelay
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] server in
                guard let self else { return }
                title.accept(server.displayName)
                exampleText.accept(self.makeExampleText(for: selectedExample.value))
            })
            .disposed(by: rx.disposeBag)

        input.testExample
            .asObservable()
            .flatMapLatest { [weak self] type -> Observable<String> in
                guard let self else { return .empty() }
                return self.sendTestPush(for: type)
            }
            .bind(to: showSnackbar)
            .disposed(by: rx.disposeBag)

        return Output(
            title: title.asDriver(),
            exampleText: exampleText.asDriver(),
            showSnackbar: showSnackbar.asDriver(onErrorDriveWith: .empty())
        )
    }

    private func sendTestPush(for type: ExampleType) -> Observable<String> {
        let server = ServerManager.shared.currentServer
        guard !server.key.isEmpty else {
            return .just("deviceNotRegistered".localized)
        }
        guard let request = makeTestRequest(for: type, server: server) else {
            return .just("InvalidServer".localized)
        }

        return Observable.create { observer in
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                DispatchQueue.main.async {
                    if error == nil,
                       let response = response as? HTTPURLResponse,
                       (200..<300).contains(response.statusCode)
                    {
                        observer.onNext("testPushSent".localized)
                    } else {
                        observer.onNext("testPushFailed".localized(with: "\((response as? HTTPURLResponse)?.statusCode ?? 0) \(error?.localizedDescription ?? "")"))
                    }
                    observer.onCompleted()
                }
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func makeTestRequest(for type: ExampleType, server: Server) -> URLRequest? {
        guard var components = URLComponents(string: server.address) else { return nil }

        switch type {
        case .get:
            components.path = components.path + "/\(server.key)/\(ExampleParams.title.urlEncoded())/\(ExampleParams.body.urlEncoded())"
            components.queryItems = [
                URLQueryItem(name: "group", value: ExampleParams.group),
                URLQueryItem(name: "ttl", value: String(ExampleParams.ttl))
            ]
            guard let url = components.url else { return nil }
            return URLRequest(url: url)

        case .post:
            components.path = components.path + "/\(server.key)"
            guard let url = components.url else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "title=\(ExampleParams.title.urlEncoded())&body=\(ExampleParams.body.urlEncoded())&group=\(ExampleParams.group.urlEncoded())&ttl=\(ExampleParams.ttl)".data(using: .utf8)
            return request

        case .json:
            components.path = components.path + "/push"
            guard let url = components.url else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: [
                "device_key": server.key,
                "title": ExampleParams.title,
                "body": ExampleParams.body,
                "group": ExampleParams.group,
                "ttl": ExampleParams.ttl
            ])
            return request
        }
    }

    private func makeExampleText(for type: ExampleType) -> String {
        let server = ServerManager.shared.currentServer
        let address = server.address.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let key = server.key.isEmpty ? "YOUR_KEY" : server.key
        switch type {
        case .get:
            return "curl -X GET \(address)/\(key)/\(ExampleParams.title)/\(ExampleParams.body)?group=\(ExampleParams.group)&ttl=\(ExampleParams.ttl)"
        case .post:
            return """
            curl -X POST \(address)/\(key) \\
              -d "title=\(ExampleParams.title)" \\
              -d "body=\(ExampleParams.body)" \\
              -d "group=\(ExampleParams.group)" \\
              -d "ttl=\(ExampleParams.ttl)"
            """
        case .json:
            return """
            curl -X POST \(address)/push \\
              -H "Content-Type: application/json" \\
              -d '{
                "device_key": "\(key)",
                "title": "\(ExampleParams.title)",
                "body": "\(ExampleParams.body)",
                "group": "\(ExampleParams.group)",
                "ttl": \(ExampleParams.ttl)
              }'
            """
        }
    }
}
