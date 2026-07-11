//
//  TabBarView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 07/02/2026.
//

import SwiftUI
import Navigation

struct TabBarView: View {

    @ObservedObject var mainCoordinator: MainCoordinator

    var body: some View {
        TabView(selection: $mainCoordinator.selectedTab) {
            NavigationHost(coordinator: mainCoordinator.homeCoordinator) {
                HomeView()
                    .environmentObject(mainCoordinator)
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(TabBar.home)
            NavigationHost(coordinator: mainCoordinator.servicesCoordinator) {
                ServicesView()
                    .environmentObject(mainCoordinator)

            }
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text("Services")
            }
            .tag(TabBar.services)
        }
    }
}

enum TabBar {
    case home
    case services
}

#Preview {
    TabBarView(mainCoordinator: .init())
}

struct RootView: View {

    @ObservedObject var coordinator: MainCoordinator

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    var body: some View {
        TabBarView(mainCoordinator: coordinator)
    }
}

struct AppSplitView: View {

    @ObservedObject var coordinator: NavigationCoordinator

    @State var style: NavigationSplitViewVisibility = .doubleColumn

    enum SidebarItem: String, CaseIterable, Identifiable {
        case home
        case services
        var id: String { rawValue }
    }

    @State private var selectedItem: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases) { item in
                Button {
                    selectedItem = item
                } label: {
                    Label(
                        item.rawValue.capitalized,
                        systemImage: item == .home ? "house" : "magnifyingglass"
                    )
                }
            }
        } detail: {
            switch selectedItem {
            case .home:
                NavigationStack { HomeView() }
            case .services:
                NavigationHost(coordinator: coordinator) {
                    ServicesView().environmentObject(coordinator)
                }
            case .none:
                EmptyView()
            }
        }
    }
}
