//
//  BarkApi.swift
//  Bark
//
//  Created by Jian Qin on 10/10/26.
//

import Foundation

/// Mirrors the phone's `BarkApi` Moya target, built on plain `URLRequest`.
enum BarkApi {
    case register(address: URL, key: String?, devicetoken: String) // 注册设备
    case push(address: URL, parameters: [String: String])
}

extension BarkApi {
    var baseURL: URL {
        switch self {
        case let .register(address, _, _), let .push(address, _):
            return address
        }
    }

    var path: String {
        switch self {
        case .register:
            return "register"
        case .push:
            return "push"
        }
    }

    var method: String {
        switch self {
        case .register:
            return "GET"
        case .push:
            return "POST"
        }
    }

    var parameters: [String: String]? {
        switch self {
        case let .register(_, key, devicetoken):
            var params = ["devicetoken": devicetoken]
            if let key = key {
                params["key"] = key
            }
            return params
        case let .push(_, parameters):
            return parameters
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        switch self {
        case .register:
            // GET parameters go in the query, like Moya's `URLEncoding.default`.
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw BarkServerError("Invalid server address.")
            }
            components.queryItems = parameters?.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
            // A literal plus is interpreted as a space by form-style query parsers.
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            guard let requestURL = components.url else { throw BarkServerError("Invalid registration address.") }
            var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.httpMethod = method
            return request
        case .push:
            var request = URLRequest(url: url, timeoutInterval: 20)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(parameters ?? [:])
            return request
        }
    }
}

struct BarkServerError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}
