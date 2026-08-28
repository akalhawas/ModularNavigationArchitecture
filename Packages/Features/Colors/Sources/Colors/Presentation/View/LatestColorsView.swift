//
//  LatestColorsView.swift
//  Colors
//

import SwiftUI
import Navigation

struct LatestColorsView: View {

    @StateObject private var viewModel: LatestColorsViewModel
    @EnvironmentObject var router: NavigationRouter

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
            Button {
                router.navigate(to: ColorsRoute.colorsList)
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
                            router.presentSheet(ColorsRoute.colorDetail(id: color.id))
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
        .padding(10)
        .frame(width: 140, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
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
