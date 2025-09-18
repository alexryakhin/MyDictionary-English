//
//  WeeklyProgressChart.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct WeeklyProgressChart: View {
    let data: [DailyProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart header
            HStack {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(totalMinutes) min total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Chart bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.day) { dayData in
                    VStack(spacing: 4) {
                        // Progress bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayData.minutes > 0 ? Color.accent : Color.secondary.opacity(0.3))
                            .frame(width: 32, height: max(4, CGFloat(dayData.minutes) * 0.8))
                        
                        // Day label
                        Text(dayData.day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 80)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .accent, label: "Study Time")
                LegendItem(color: .green, label: "Goals Met")
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var totalMinutes: Int {
        data.reduce(0) { $0 + $1.minutes }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Daily Progress Model

struct DailyProgress {
    let day: String
    let minutes: Int
    let goalsMet: Int
    let totalGoals: Int
    
    static let sampleData: [DailyProgress] = [
        DailyProgress(day: "Mon", minutes: 25, goalsMet: 3, totalGoals: 4),
        DailyProgress(day: "Tue", minutes: 35, goalsMet: 4, totalGoals: 4),
        DailyProgress(day: "Wed", minutes: 20, goalsMet: 2, totalGoals: 4),
        DailyProgress(day: "Thu", minutes: 45, goalsMet: 4, totalGoals: 4),
        DailyProgress(day: "Fri", minutes: 30, goalsMet: 3, totalGoals: 4),
        DailyProgress(day: "Sat", minutes: 15, goalsMet: 2, totalGoals: 3),
        DailyProgress(day: "Sun", minutes: 0, goalsMet: 0, totalGoals: 2)
    ]
}

#Preview {
    WeeklyProgressChart(data: DailyProgress.sampleData)
        .padding()
}
