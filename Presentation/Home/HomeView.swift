//
//  HomeView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Colors
import Navigation

struct HomeView: View {

    var body: some View {        
        VStack {

        }
        .navigationTitle("Home")
    }
}

#Preview {
    let _ = AppComposition.bootstrapFeatures()
    HomeView()
        .environmentObject(MainCoordinator())
}
