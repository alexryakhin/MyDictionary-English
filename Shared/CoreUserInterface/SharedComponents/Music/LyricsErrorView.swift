//
//  LyricsErrorView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/13/25.
//

import SwiftUI

struct LyricsErrorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(Loc.MusicDiscovering.Sheet.LyricsUnavailable.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(Loc.MusicDiscovering.Sheet.LyricsUnavailable.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}
