//
//  VocabularyLineChart.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/2/25.
//

import SwiftUI
import Charts

struct VocabularyLineChart: View {

    struct Model: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    let data: [Model]

    private var maxValue: Int {
        data.map { $0.count }.max() ?? 1
    }

    private var minValue: Int {
        data.map { $0.count }.min() ?? 0
    }
    
    private var valueRange: CGFloat {
        let range = maxValue - minValue
        return range > 0 ? CGFloat(range) : 1.0 // Prevent division by zero
    }

    var body: some View {
        VStack(spacing: 8) {
            // Chart
            Chart(data) { model in
                LineMark(
                    x: .value("Date", model.date),
                    y: .value("Words", model.count)
                )
                .foregroundStyle(.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Axis labels
            HStack {
                Text("\(minValue) words")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(maxValue) words")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
        }
    }
}
