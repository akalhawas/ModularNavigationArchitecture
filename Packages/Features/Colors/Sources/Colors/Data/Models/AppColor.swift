//
//  AppColor.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

struct AppColor: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let year: Int
    let color: String
    let pantoneValue: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case year
        case color
        case pantoneValue = "pantone_value"
    }
}
