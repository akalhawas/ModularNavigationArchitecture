//
//  ColorsCrossFeatureDelegate.swift
//  Colors
//
//  Created by ali alhawas on 26/08/2026.
//

import Navigation
import Combine

public protocol ColorsCrossFeatureDelegate: AnyObject {
    func onPrimaryAction(router: NavigationRouter, id: Int, onReturn: @escaping () -> Void)
}
