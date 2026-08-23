//
//  UsersDestination.swift
//  UsersAPI
//
//  Created by ali alhawas on 24/07/2026.
//

import Navigation

/// Defines public entry points into the Users feature.
///
/// Used for cross-feature navigation and deep linking. This is the only
/// thing other features/the app need to depend on to navigate into Users —
/// it does not pull in Users' SwiftUI views, networking, or use cases.
public enum UsersDestination: NavigationDestination {
    case details(id: Int)
}
