//
//  ColorsCrossFeatureDelegate.swift
//  Colors
//
//  Created by ali alhawas on 26/08/2026.
//


import Navigation

public protocol ColorsCrossFeatureDelegate: AnyObject {
    func onPrimaryAction(coordinator: NavigationRouter, id: Int)
}
