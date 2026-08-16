//
//  User.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

struct User: Decodable, Identifiable, Equatable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let avatar: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case avatar
    }
}
