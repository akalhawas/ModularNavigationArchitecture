//
//  UsersDestination.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import Navigation

/// Entry points into the Users feature reachable via ``UsersDeepLinkMapper``
/// and registered with ``RouteRegistry``. Other features never reference
/// this type directly — they navigate in through a URL resolved by
/// `DeepLinkRouter`, so this stays internal to the Users module.
enum UsersDestination: NavigationDestination {
    case details(id: Int)
}
