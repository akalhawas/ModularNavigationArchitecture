//
//  UserListResponse.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

struct UserListResponse: Decodable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
    let data: [User]
    let support: SupportInfo

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case total
        case totalPages = "total_pages"
        case data
        case support
    }
}
