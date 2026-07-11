//
//  DetailParams.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Carries input required to navigate to FeatureB detail screen.
///
/// Part of the shared navigation contract.
public struct FeatureBDetailParams: Hashable {
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
}
