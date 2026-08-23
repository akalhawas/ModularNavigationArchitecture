//
//  ColorsDestination.swift
//  ColorsAPI
//
//  Created by ali alhawas on 11/08/2026.
//

import Navigation

/// Defines public entry points into the Colors feature.
///
/// Used for cross-feature navigation and deep linking. This is the only
/// thing other features/the app need to depend on to navigate into Colors —
/// it does not pull in Colors' SwiftUI views, networking, or use cases.
public enum ColorsDestination: NavigationDestination {
    case details(id: Int)
}
