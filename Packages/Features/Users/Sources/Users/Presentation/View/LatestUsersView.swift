//
//  LatestUsersView.swift
//  Users
//

import SwiftUI
import Navigation

struct LatestUsersView: View {

    @StateObject private var viewModel: LatestUsersViewModel
    @EnvironmentObject var coordinator: NavigationRouter

    init(viewModel: LatestUsersViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .task {
            if viewModel.users.isEmpty {
                viewModel.fetchLatestUsers()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Latest Users")
                .font(.title2.bold())
            Spacer()
            Button {
                coordinator.navigate(to: UsersRoute.usersList)
            } label: {
                HStack(spacing: 4) {
                    Text("See All")
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 8) {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    viewModel.fetchLatestUsers()
                }
                .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        } else if viewModel.users.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.users) { user in
                        Button {
                            coordinator.navigate(to: UsersRoute.userDetail(id: user.id))
                        } label: {
                            LatestUserCard(user: user)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct LatestUserCard: View {

    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: user.avatar)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            Text("\(user.firstName) \(user.lastName)")
                .font(.subheadline.bold())
                .lineLimit(1)

            Text(user.email)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(width: 140, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

#Preview {
    LatestUsersView(
        viewModel: LatestUsersViewModel(
            fetchUsersUseCase: FetchUsersUseCaseImp(repository: UserRepositoryMock()),
            limit: 10
        )
    )
}
