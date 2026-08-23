//
//  ColorsDeepLinkMapper.swift
//  Colors
//
//  Created by ali alhawas on 22/08/2026.
//

import SwiftUI
import Navigation
import ColorsAPI

struct ColorsDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"

    func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "colors" else { return nil }

        switch url.path {
        case "/details":
            guard let id = url.queryItem("id").flatMap(Int.init) else { return nil }
            return ColorsDestination.details(id: id)

//        case "/list":
//            return ColorsDestination.list

        default:
            return nil
        }
    }
}
