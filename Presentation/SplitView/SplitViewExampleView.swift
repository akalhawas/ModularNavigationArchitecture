//
//  SplitViewExampleView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 30/09/2026.
//

import SwiftUI
import FeatureA
import FeatureB
import Navigation

enum SplitViewRoute: Route {
    case splitView

    func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .splitView:
            SplitViewExampleView { coordinator.pop() }
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct SplitViewExampleView: View {

    enum SidebarItem: String, CaseIterable, Identifiable {
        case featureA
        case featureB

        var id: String { rawValue }

        var title: String {
            switch self {
            case .featureA: "Feature A"
            case .featureB: "Feature B"
            }
        }

        var systemImage: String {
            switch self {
            case .featureA: "a.square"
            case .featureB: "b.square"
            }
        }
    }

    let onClose: () -> Void

    @StateObject private var detailCoordinator = NavigationCoordinator()
    @State private var selectedItem: SidebarItem? = .featureA
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.systemImage)
                }
            }
            .navigationTitle("Split View")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                }
            }
        } detail: {
            NavigationHost(coordinator: detailCoordinator) {
                detailRoot
            }
        }
        .onChange(of: selectedItem) {
            detailCoordinator.popToRoot()
        }
    }

    @ViewBuilder
    private var detailRoot: some View {
        switch selectedItem {
        case .featureA:
            FeatureARoute.mainScreen.makeView(coordinator: detailCoordinator)
        case .featureB:
            FeatureBRoute.mainScreen.makeView(coordinator: detailCoordinator)
        case .none:
            Text("Select a feature")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SplitViewExampleView(onClose: {})
}
