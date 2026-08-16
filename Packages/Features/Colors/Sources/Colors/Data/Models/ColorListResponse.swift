//
//  ColorListResponse.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

struct ColorListResponse: Decodable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
    let data: [AppColor]
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
