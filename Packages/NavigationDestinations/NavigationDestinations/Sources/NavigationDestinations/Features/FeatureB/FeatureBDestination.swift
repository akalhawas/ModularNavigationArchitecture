//
//  FeatureBDestination.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI
import Navigation

/// Defines public entry points into Feature.
///
/// Used for cross-feature navigation and deep linking.
public enum FeatureBDestination: NavigationDestination {
    case mainScreen
    case thirdScreen(id: String)
}
