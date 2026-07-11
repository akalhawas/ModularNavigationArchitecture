//
//  FeatureADeepLinkMapper.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 30/05/2026.
//

import SwiftUI
import Navigation
import NavigationDestinations

public struct FeatureBDeepLinkMapper: DeepLinkMapper {
    
    // xcrun simctl openurl booted "com.ali.modularizedbyfeature://featureB/subDetail?id=123"
    
    public init() {}
    public func map(url: URL) -> (any NavigationDestination)? {

        if url.host == "featureB",
           url.path == "/subDetail",
           let id = url.queryItem("id") {
            return FeatureBDestination.thirdScreen(id: id)
        }
        
        return nil
    }
}
