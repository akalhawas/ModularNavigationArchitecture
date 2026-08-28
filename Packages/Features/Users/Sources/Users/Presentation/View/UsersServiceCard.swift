//
//  UsersServiceCard.swift
//  Users
//

import SwiftUI
import Navigation

struct UsersServiceCard: View {

    @EnvironmentObject var coordinator: NavigationRouter

    var body: some View {
        Button {
            coordinator.navigate(to: UsersRoute.usersList)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Users")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Browse team members")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UsersServiceCard()
        .environmentObject(NavigationRouter())
        .padding()
}
