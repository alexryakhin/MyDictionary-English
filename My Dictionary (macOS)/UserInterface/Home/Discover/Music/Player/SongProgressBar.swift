//
//  SongProgressBar.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct SongProgressBar: View {
    @Binding var isDragging: Bool
    @Binding var progress: TimeInterval
    var duration: TimeInterval

    private var normalizedProgress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(max(progress / duration, 0), 1))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(width * normalizedProgress, 0))
            }
            .clipShape(.capsule)
            .frame(height: isDragging ? 14 : 10)
            .scaleEffect(isDragging ? 1.05 : 1.0, anchor: .center)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .animation(.default, value: progress)
            .contentShape(.capsule)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }
                        
                        let newValue = time(at: value.location.x, totalWidth: width)
                        setProgress(newValue)
                    }
                    .onEnded { value in
                        let newValue = time(at: value.location.x, totalWidth: width)
                        setProgress(newValue)
                        isDragging = false
                    }
            )
        }
        .frame(height: 20)
    }
    
    private func time(at xPosition: CGFloat, totalWidth: CGFloat) -> TimeInterval {
        guard duration > 0, totalWidth > 0 else { return 0 }
        let clampedPosition = min(max(xPosition, 0), totalWidth)
        let percentage = clampedPosition / totalWidth
        return TimeInterval(percentage) * duration
    }

    private func setProgress(_ progress: TimeInterval) {
        guard self.progress != progress else { return }
        self.progress = progress
    }
}

