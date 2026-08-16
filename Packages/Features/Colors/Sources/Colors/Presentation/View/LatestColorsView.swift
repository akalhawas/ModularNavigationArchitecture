//
//  LatestColorsView.swift
//  Colors
//

import SwiftUI
import Navigation

struct LatestColorsView: View {

    @StateObject private var viewModel: LatestColorsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator

    init(viewModel: LatestColorsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .task {
            if viewModel.colors.isEmpty {
                viewModel.fetchLatestColors()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Latest Colors")
                .font(.title2.bold())
            Spacer()
            Button("See All") {
                coordinator.navigate(to: ColorsRoute.colorsList)
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
                    viewModel.fetchLatestColors()
                }
                .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        } else if viewModel.colors.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.colors) { color in
                        Button {
                            coordinator.navigate(to: ColorsRoute.colorDetail(id: color.id))
                        } label: {
                            LatestColorCard(color: color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct LatestColorCard: View {

    let color: AppColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: color.color))
                .frame(width: 116, height: 80)

            Text(color.name.capitalized)
                .font(.subheadline.bold())
                .lineLimit(1)

            Text("\(color.year)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(width: 140, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    LatestColorsView(
        viewModel: LatestColorsViewModel(
            fetchColorsUseCase: FetchColorsUseCaseImp(repository: ColorRepositoryMock()),
            limit: 10
        )
    )
}
