//
//  ColorsDestination.swift
//  Colors
//
//  Created by ali alhawas on 11/08/2026.
//

import Navigation

/// Entry points into the Colors feature, registered with ``RouteRegistry``.
/// Other features never reference this type directly — they navigate in
/// through a URL resolved by `DeepLinkRouter`, so this stays internal to
/// the Colors module.
enum ColorsDestination: NavigationDestination {
    case details(id: Int)
}
