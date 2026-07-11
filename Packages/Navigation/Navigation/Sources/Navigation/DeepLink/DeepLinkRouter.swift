//
//  DeepLinkRouter.swift
//  Navigation
//
//  Created by ali alhawas on 30/05/2026.
//

import SwiftUI

/// Resolves incoming URLs into ``NavigationDestination`` values using the
/// registered ``DeepLinkMapper`` implementations.
public final class DeepLinkRouter {

    private let mappers: [DeepLinkMapper]

    public init(mappers: [DeepLinkMapper]) {
        self.mappers = mappers
    }

    /// Resolves a URL into a navigation destination.
    ///
    /// The registered mappers are evaluated in order until one returns a
    /// matching destination.
    ///
    /// - Parameter url: The incoming deep link URL.
    /// - Returns: The resolved ``NavigationDestination`` if one exists;
    ///   otherwise, `nil`.
    public func resolve(url: URL) -> (any NavigationDestination)? {
        for mapper in mappers {
            if let destination = mapper.map(url: url) {
                return destination
            }
        }
        return nil
    }
}
