//
//  ServicesView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Navigation

struct ServicesView: View {
    
    @EnvironmentObject var coordinator: MainCoordinator
    
    @State private var showSheet: Bool = false
    var body: some View {
        VStack {
            Button {
                coordinator.navigateToUsers(coordinator: coordinator.servicesCoordinator)
            } label: {
                Text("Users")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button {
                coordinator.navigateToColors(coordinator: coordinator.servicesCoordinator)
            } label: {
                Text("Colors")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .navigationTitle("Services")
        .padding()
    }
}

#Preview {
    ServicesView()
}
