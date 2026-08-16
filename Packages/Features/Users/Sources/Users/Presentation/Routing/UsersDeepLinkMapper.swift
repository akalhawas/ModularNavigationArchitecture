//
//  UsersDeepLinkMapper.swift
//  Users
//
//  Created by ali alhawas on 30/05/2026.
//

import SwiftUI
import Navigation
import UsersAPI

public struct UsersDeepLinkMapper: DeepLinkMapper {
    
    // xcrun simctl openurl booted "com.ali.modularizedbyfeature://users/details?id=1"
    
    public init() {}
    public func map(url: URL) -> (any NavigationDestination)? {

        if url.host == "users",
           url.path == "/details",
           let id = url.queryItem("id") {
            return UsersDestination.details(id: Int(id) ?? 0)
        }
        
        return nil
    }
}
