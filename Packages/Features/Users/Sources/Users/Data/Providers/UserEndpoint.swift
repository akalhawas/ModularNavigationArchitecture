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

    var baseURL: URL {
        URL(string: "https://reqres.in/api")!
    }

    var path: String {
        switch self {
        case .list:
            return "/users"
        case .detail(let id):
            return "/users/\(id)"
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
        case .detail:
            return nil
        }
    }
}
