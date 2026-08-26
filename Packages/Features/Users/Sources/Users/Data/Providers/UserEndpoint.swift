//
//  UserEndpoint.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

import Foundation
import NetworkService

enum UserEndpoint: Endpoint {
    case list(page: Int)
    case detail(id: Int)
    /// Placeholder path — point this at the real permission-check endpoint.
    case permission(id: Int)

    var baseURL: URL {
        URL(string: "https://reqres.in/api")!
    }

    var path: String {
        switch self {
        case .list:
            return "/users"
        case .detail(let id):
            return "/users/\(id)"
        case .permission(let id):
            return "/users/\(id)/permission"
        }
    }

    var method: HTTPMethod {
        .get
    }

    var headers: [String: String]? {
        ["x-api-key": Secrets.reqresAPIKey]
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let page):
            return [URLQueryItem(name: "page", value: "\(page)")]
        case .detail, .permission:
            return nil
        }
    }
}
