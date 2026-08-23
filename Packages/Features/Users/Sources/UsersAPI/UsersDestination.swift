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
    /// - Parameter onDetailAction: Called by the Users detail screen's own
    ///   view model when its action happens — not tied to navigation/pop
    ///   timing. `nil` for anything that can't supply one, e.g. a real OS
    ///   deep link resolved from a URL.
    case details(id: Int, onDetailAction: ActionCallback<Void>? = nil)

    /// Convenience for callers that just want to pass a closure directly,
    /// e.g. `UsersDestination.details(id: 1) { ... }`.
    public static func details(id: Int, onDetailAction: @escaping () -> Void) -> UsersDestination {
        .details(id: id, onDetailAction: ActionCallback(onDetailAction))
    }
}
