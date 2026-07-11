//
//  FeatureAView.swift
//  FeatureA
//
//  Created by ali alhawas on 03/11/2025.
//

import SwiftUI
import Navigation
import NavigationDestinations

// MARK: List
struct FeatureAListView: View {

    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        VStack {
            // MARK: Navigate
            Button {
                coordinator.navigate(to: FeatureARoute.firstScreen)
            } label: {
                Text("First Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()

            // MARK: Navigate
            Button {
                let destination = FeatureBDestination.mainScreen
                guard let route = RouteRegistry.shared.resolve(destination) else { return }
                coordinator.navigate(to: route)
            } label: {
                Text("Feature (B)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.pop()
            } label: {
                Text("Back")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Feature (A)")
//        .toolbar(coordinator.routes.isEmpty ? .visible : .hidden, for: .tabBar)
//        .animation(.easeInOut(duration: 0.3), value: coordinator.routes.isEmpty)
    }
}

// MARK: Detail
struct FeatureADetailView: View {
    
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Button {
                coordinator.navigate(to: FeatureARoute.secondScreen)
            } label: {
                Text("Second Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            Button {
                dismiss()
                coordinator.pop()
            } label: {
                Text("Back")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("(A) First Screen")
        .padding()
    }
}

// MARK: Sub Detail
struct FeatureASubDetailView: View {
    
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        VStack {
            Button {
                coordinator.navigate(to: FeatureARoute.thirdScreen(id: "123"))
            } label: {
                Text("Third Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            Button {
                coordinator.pop()
            } label: {
                Text("Back")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("(A) Second Screen")
        .padding()
    }
}

// MARK: Sub Sub Detail
struct FeatureASubSubDetailView: View {

    let flightID: String
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Present:")
                .padding()
            
            Button {
                coordinator.presentSheet(FeatureARoute.mainScreen, detents: [.height(300), .medium])
            } label: {
                Text("Present")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.presentSheet(FeatureARoute.mainScreen)
            } label: {
                Text("Present")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
                 
            Button {
                coordinator.presentFullScreen(FeatureARoute.firstScreen)
            } label: {
                Text("Present Full Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            Text("Pop:")
                .padding()
            Button {
                coordinator.pop()
            } label: {
                Text("Back to Second Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.pop(count: 2)
            } label: {
                Text("Back to First Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.popTo {
                    $0.matches(FeatureARoute.mainScreen)
                }
            } label: {
                Text("Back to Main Screen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.popToRoot()
            } label: {
                Text("Back to Root")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("(A) Third Screen")
        .padding()
    }
}

#Preview {
    FeatureAListView()
}
