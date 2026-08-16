//
//  ColorEndpoint.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import NetworkService

enum ColorEndpoint: Endpoint {
    case list(page: Int)
    case detail(id: Int)

    var baseURL: URL {
        URL(string: "https://reqres.in/api")!
    }

    var path: String {
        switch self {
        case .list:
            return "/unknown"
        case .detail(let id):
            return "/unknown/\(id)"
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
