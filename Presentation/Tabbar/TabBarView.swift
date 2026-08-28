//
//  TabBarView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 07/02/2026.
//

import SwiftUI
import Navigation
enum TabBar: String, CaseIterable, Identifiable {
    case home
    case services
    var id: String { rawValue }
}

struct TabBarView: View {

    @StateObject var appCoordinator: AppCoordinator = AppCoordinator()

    var body: some View {
        TabView(selection: $appCoordinator.selectedTab) {

            NavigationHost(router: appCoordinator.homeRouter) {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(TabBar.home)

            NavigationHost(router: appCoordinator.servicesRouter) {
                ServicesView()
            }
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text("Services")
            }
            .tag(TabBar.services)
            
        }
    }
}

#Preview {
    TabBarView(appCoordinator: .init())
}
