//
//  ServicesView.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 21/06/2026.
//

import SwiftUI
import Navigation
import Users
import Colors

struct ServicesView: View {

    @EnvironmentObject var coordinator: NavigationRouter

    var body: some View {
        VStack {
            UsersModule.makeServicesCard()
            ColorsModule.makeServicesCard()
            Spacer()
        }
        .navigationTitle("Services")
        .padding()
    }
}

#Preview {
    ServicesView()
}
