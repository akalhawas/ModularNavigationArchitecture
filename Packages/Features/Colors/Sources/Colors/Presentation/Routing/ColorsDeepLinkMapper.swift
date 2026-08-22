//
//  ColorsDeepLinkMapper.swift
//  Colors
//
//  Created by ali alhawas on 22/08/2026.
//

import SwiftUI
import Navigation

struct ColorsDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"

    func map(url: URL) -> (any NavigationDestination)? {

        if url.host == "colors",
           url.path == "/details",
           let id = url.queryItem("id") {
            return ColorsDestination.details(id: Int(id) ?? 0)
        }
        
        return nil
    }
}
