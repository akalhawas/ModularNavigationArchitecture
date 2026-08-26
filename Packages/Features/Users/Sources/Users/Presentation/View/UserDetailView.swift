//
//  UserDetailView.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation

struct UserDetailView: View {

    @StateObject private var viewModel: UserDetailViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    init(viewModel: UserDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            VStack {
                content
                    .navigationTitle("Details")
                    .task {
                        if viewModel.user == nil {
                            viewModel.fetchUser()
                        }
                    }
                
                Button {
                    viewModel.notifyDetailAction()
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
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                viewModel.fetchUser()
            }
        } else if let user = viewModel.user {
            detail(for: user)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func detail(for user: User) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: user.avatar)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())

            Text("\(user.firstName) \(user.lastName)")
                .font(.title2.bold())

            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.top, 32)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        UserDetailView(
            viewModel: UserDetailViewModel(
                userId: 1,
                fetchUserDetailUseCase: FetchUserDetailUseCaseImp(repository: UserRepositoryMock())
            )
        )
    }
}
