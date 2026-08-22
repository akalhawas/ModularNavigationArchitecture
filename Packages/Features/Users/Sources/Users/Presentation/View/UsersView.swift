//
//  UsersView.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation

struct UsersView: View {

    @StateObject private var viewModel: UsersViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    init(viewModel: UsersViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Users")
            .task {
                if viewModel.users.isEmpty {
                    viewModel.fetchUsers()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                viewModel.fetchUsers()
            }
        } else if viewModel.users.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.users) { user in
                Button {
                    coordinator.navigate(to: UsersRoute.userDetail(id: user.id))
                } label: {
                    UserRow(user: user)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.fetchUsers()
            }
        }
    }
}

private struct UserRow: View {

    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatar)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        UsersView(
            viewModel: UsersViewModel(
                fetchUsersUseCase: FetchUsersUseCaseImp(repository: UserRepositoryMock())
            )
        )
    }
}
