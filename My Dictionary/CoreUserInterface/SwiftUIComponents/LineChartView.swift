//
//  LineChartView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct LineChartView: View {
    struct Value: Identifiable {
        let id: Int = UUID().hashValue
        let title: String
        let color: Color
        let percentage: Double

        init(title: String, color: Color, percentage: Double) {
            self.title = title
            self.color = color
            self.percentage = percentage
        }
    }

    private let values: [Value]
    private let showsDescription: Bool

    init(
        values: [Value],
        showsDescription: Bool = true
    ) {
        self.values = values
        self.showsDescription = showsDescription
    }

    private let gridItemLayout = [GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 8)]

    var body: some View {
        VStack(spacing: 16) {
            // Stock Distribution Progress Bar
            GeometryReader { geometry in
                let totalSpacing = CGFloat(values.count - 1) * 2 // Total spacing between segments
                let totalWidth = geometry.size.width - totalSpacing // Width available for segments

                HStack(spacing: 2) {
                    ForEach(values) { value in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(value.color)
                            .frame(width: totalWidth * CGFloat(value.percentage / 100))
                    }
                }
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 8) // Set fixed height

            if showsDescription {
                // Instrument Info Grid
                LazyVGrid(columns: gridItemLayout, alignment: .leading, spacing: 8) {
                    ForEach(values) { value in
                        HStack(alignment: .top, spacing: 4) {
                            Circle()
                                .fill(value.color)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(value.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text("\(value.percentage, specifier: "%.1f")%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LineChartView(values: [
        .init(title: "Stocks", color: .blue, percentage: 40),
        .init(title: "Bonds", color: .red, percentage: 30),
        .init(title: "Crypto", color: .green, percentage: 20),
        .init(title: "Commodities", color: .orange, percentage: 10)
    ])
    .padding(16)
}
