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

    @ObservedObject var mainCoordinator: MainCoordinator

    var body: some View {
        TabView(selection: $mainCoordinator.selectedTab) {
            
            NavigationHost(coordinator: mainCoordinator.homeCoordinator) {
                HomeView()
                    .environmentObject(mainCoordinator.homeCoordinator)
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(TabBar.home)
            
            NavigationHost(coordinator: mainCoordinator.servicesCoordinator) {
                ServicesView()
                    .environmentObject(mainCoordinator.servicesCoordinator)
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
    TabBarView(mainCoordinator: .init())
}

struct RootView: View {

    @ObservedObject var coordinator: MainCoordinator

    var body: some View {
        TabBarView(mainCoordinator: coordinator)
    }
}
