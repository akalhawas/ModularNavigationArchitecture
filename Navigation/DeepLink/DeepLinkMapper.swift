//
//  DeepLinkMapper.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 30/05/2026.
//

import SwiftUI

/// Maps an incoming URL to a strongly typed ``NavigationDestination``.
public protocol DeepLinkMapper {
    /// Attempts to map the given URL to a navigation destination.
    ///
    /// - Parameter url: The incoming deep link URL.
    /// - Returns: A ``NavigationDestination`` if the URL is supported;
    ///   otherwise, `nil`.
    func map(url: URL) -> (any NavigationDestination)?
}
