//
//  FeatureBView.swift
//  FeatureB
//
//  Created by ali alhawas on 17/10/2025.
//

import SwiftUI
import Navigation

// MARK: List
struct FeatureBListView: View {
    
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    init() {}
    
    var body: some View {
        VStack {
            // MARK: Navigate
            Button {
                coordinator.navigate(to: FeatureBRoute.firstScreen)
            } label: {
                Text("First Screen")
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
        .padding()
        .navigationTitle("Feature (B)")
    }
}

// MARK: Detail
struct FeatureBDetailView: View {

    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Button {
                coordinator.navigate(to: FeatureBRoute.secondScreen)
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
        .navigationTitle("(B) First Screen")
        .padding()
    }
}

// MARK: Sub Detail
struct FeatureBSubDetailView: View {

    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        VStack {
            Button {
                coordinator.navigate(to: FeatureBRoute.thirdScreen(id: "123"))
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
        .navigationTitle("(B) Second Screen")
        .padding()
    }
}

// MARK: Sub Sub Detail
struct FeatureBSubSubDetailView: View {

    let flightID: String
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Present:")
                .padding()
            
            Button {
                coordinator.presentSheet(FeatureBRoute.mainScreen, detents: [.height(300), .medium])
            } label: {
                Text("Present")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button {
                coordinator.presentSheet(FeatureBRoute.mainScreen)
            } label: {
                Text("Present")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
                 
            Button {
                coordinator.presentFullScreen(FeatureBRoute.firstScreen)
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
                    $0.matches(FeatureBRoute.mainScreen)
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
        .navigationTitle("(B) Third Screen")
        .padding()
    }
}

#Preview {
    FeatureBListView()
}
