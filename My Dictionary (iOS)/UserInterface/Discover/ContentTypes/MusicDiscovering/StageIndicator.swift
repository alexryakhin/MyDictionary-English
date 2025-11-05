//
//  StageIndicator.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StageIndicator: View {
    let stage: LearningStage
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: stage.icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white).frame(width: 24, height: 24))
                }
            }
            
            Text(stage.rawValue)
                .font(.caption2)
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundColor: Color {
        if isActive {
            return .accent.opacity(0.2)
        } else if isCompleted {
            return .green.opacity(0.2)
        } else {
            return .gray.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        if isActive {
            return .accent
        } else if isCompleted {
            return .green
        } else {
            return .gray
        }
    }
}

