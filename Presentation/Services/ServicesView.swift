//
//  ServicesView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import FeatureA
import FeatureB
import Navigation

struct ServicesView: View {
    
    @EnvironmentObject var coordinator: MainCoordinator
    
    var body: some View {
        VStack {
            Button {
                coordinator.servicesCoordinator.navigate(to: FeatureARoute.mainScreen)
            } label: {
                Text("Feature A")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button {
                coordinator.servicesCoordinator.navigate(to: FeatureBRoute.mainScreen)
            } label: {
                Text("Feature B")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ServicesView()
}
