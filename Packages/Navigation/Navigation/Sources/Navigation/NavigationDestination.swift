//
//  NavigationDestination.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 03/04/2026.
//

import SwiftUI

/// Represents a public navigation entry point that can be
/// resolved into a feature route through RouteRegistry.
///
/// NavigationDestination is intended for:
/// - Cross-feature navigation
/// - Deep links
/// - External feature entry points
///
/// Internal feature navigation should continue using Route directly.
public protocol NavigationDestination: Hashable {}
