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
            ScrollView {
                ColorsModule.headerHomeView(items: 2)
            }
        }
        .navigationTitle("Home")
    }
}

#Preview {
    let appCoordinator = AppCoordinator()
    let _ = AppComposition.bootstrapFeatures(appCoordinator: appCoordinator)
    HomeView()
        .environmentObject(appCoordinator)
}
