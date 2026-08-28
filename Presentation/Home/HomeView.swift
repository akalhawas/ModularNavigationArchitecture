//
//  HomeView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Colors
import Users
import Navigation

struct HomeView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ColorsModule.headerHomeView(items: 2)
                UsersModule.headerHomeView(items: 2)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Home")
    }
}

#Preview {
    HomeView()
}
