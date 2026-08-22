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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ColorsModule.makeLatestColorsView(limit: 4)
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
