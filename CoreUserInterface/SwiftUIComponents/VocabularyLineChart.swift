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

// MARK: - Previews

#Preview("Empty Chart") {
    VocabularyLineChart(data: [])
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Steady Growth") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -(29 - i), to: today) {
            let count = max(0, 10 + i * 3) // Steady growth from 10 to 100 words
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Rapid Growth") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -(29 - i), to: today) {
            let count = max(0, 50 + i * 15) // Rapid growth from 50 to 500 words
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Realistic User Data") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    // Simulate realistic user behavior: some days with growth, some without
    for i in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -(29 - i), to: today) {
            let baseCount = max(0, 10 + i * 5)
            let randomGrowth = Int.random(in: 0...3) // Random daily growth
            let count = baseCount + randomGrowth
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Week View") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<7 {
        if let date = calendar.date(byAdding: .day, value: -(6 - i), to: today) {
            let count = max(0, 10 + i * 7) // Week of growth
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Year View") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<365 {
        if let date = calendar.date(byAdding: .day, value: -(364 - i), to: today) {
            let count = max(0, i * 3) // Year of steady growth
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("New User") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -(29 - i), to: today) {
            let count = max(0, i) // New user adding first 25 words
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Advanced User") {
    let calendar = Calendar.current
    let today = Date()
    var data: [VocabularyLineChart.Model] = []
    
    for i in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -(29 - i), to: today) {
            let count = max(0, 1500 + i * 50) // Advanced user with large vocabulary
            data.append(VocabularyLineChart.Model(date: date, count: count))
        }
    }
    
    return VocabularyLineChart(data: data)
        .frame(height: 250)
        .padding()
        .background(Color(.systemBackground))
} 
