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

    @ObservedObject var appCoordinator: AppCoordinator

    var body: some View {
        TabView(selection: $appCoordinator.selectedTab) {

            NavigationHost(coordinator: appCoordinator.homeCoordinator) {
                HomeView()
                    .environmentObject(appCoordinator.homeCoordinator)
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(TabBar.home)

            NavigationHost(coordinator: appCoordinator.servicesCoordinator) {
                ServicesView()
                    .environmentObject(appCoordinator.servicesCoordinator)
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
