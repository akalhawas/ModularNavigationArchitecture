//
//  UsersDeepLinkMapper.swift
//  Users
//
//  Created by ali alhawas on 24/08/2026.
//

import Foundation
import Navigation

struct UsersDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"

    func map(url: URL) -> AnyRoute? {
        guard url.host == "users" else { return nil }

        switch url.path {
        case "/details":
            guard let id = url.queryItem("id").flatMap(Int.init) else { return nil }
            return AnyRoute(UsersRoute.userDetail(id: id))
        default:
            return nil
        }
    }
}
