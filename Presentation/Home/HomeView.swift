//
//  HomeView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Colors
struct HomeView: View {

    @EnvironmentObject var coordinator: MainCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ColorsModule.makeLatestColorsView(limit: 4)
                    .environmentObject(coordinator.homeCoordinator)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    let _ = AppComposition.bootstrapFeatures()
    HomeView()
        .environmentObject(MainCoordinator())
}
