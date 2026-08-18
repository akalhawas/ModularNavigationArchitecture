//
//  ServicesView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Navigation

struct ServicesView: View {
    
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var showSheet: Bool = false
    
    var body: some View {
        VStack {
            Button {
                coordinator.navigate(to: UsersRoute.usersList)
            } label: {
                Text("Users")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button {
                coordinator.navigate(to: ColorsRoute.colorsList)
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
