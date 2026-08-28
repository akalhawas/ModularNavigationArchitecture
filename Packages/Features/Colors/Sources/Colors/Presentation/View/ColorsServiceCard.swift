//
//  ColorsServiceCard.swift
//  Colors
//

import SwiftUI
import Navigation

struct ColorsServiceCard: View {

    @EnvironmentObject var coordinator: NavigationRouter

    var body: some View {
        Button {
            coordinator.navigate(to: ColorsRoute.colorsList)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(Color.pink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Colors")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Explore the color palette")
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
    ColorsServiceCard()
        .environmentObject(NavigationRouter())
        .padding()
}
