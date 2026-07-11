//
//  SheetConfiguration.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 03/04/2026.
//

import SwiftUI

/// Defines presentation options for sheet-based navigation.
///
/// Controls sheet behavior such as detents and drag indicator.
public struct SheetConfiguration: Equatable {
    public let detents: Set<PresentationDetent>
    public let dragIndicator: Visibility

    public init(
        detents: Set<PresentationDetent> = [.large],
        dragIndicator: Visibility = .visible
    ) {
        self.detents = detents
        self.dragIndicator = dragIndicator
    }
}
