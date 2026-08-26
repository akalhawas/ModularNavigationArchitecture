//
//  ColorDetailView.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation
struct ColorDetailView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel: ColorDetailViewModel

    
    init(viewModel: ColorDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Details")
            .task {
                if viewModel.color == nil {
                    viewModel.fetchColor()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                viewModel.fetchColor()
            }
        } else if let color = viewModel.color {
            detail(for: color)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func detail(for color: AppColor) -> some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: color.color))
                .frame(width: 96, height: 96)

            Text(color.name.capitalized)
                .font(.title2.bold())

            Text("\(color.year) · \(color.pantoneValue)")
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
        ColorDetailView(
            viewModel: ColorDetailViewModel(
                colorId: 1,
                fetchColorDetailUseCase: FetchColorDetailUseCaseImp(repository: ColorRepositoryMock())
            )
        )
    }
}
