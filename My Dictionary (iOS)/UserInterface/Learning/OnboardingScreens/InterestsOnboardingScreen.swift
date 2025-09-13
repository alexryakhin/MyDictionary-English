//
//  InterestsOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct InterestsOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.Interests.whatInterestsYou) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.Interests.helpUsMakeLessonsEngaging)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.Interests.selectInterests)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Selected count
                        if !viewModel.selectedInterests.isEmpty {
                            Text("\(viewModel.selectedInterests.count) interests selected")
                                .font(.subheadline)
                                .foregroundColor(.accent)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                // Interest Categories
                ForEach(viewModel.getInterestsCategories(), id: \.self) { category in
                    InterestCategorySection(
                        category: category,
                        interests: viewModel.filteredInterests(for: category),
                        selectedInterests: viewModel.selectedInterests,
                        onToggleInterest: viewModel.toggleInterest
                    )
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }
}

struct InterestCategorySection: View {
    let category: InterestCategory
    let interests: [LearningInterest]
    let selectedInterests: Set<LearningInterest>
    let onToggleInterest: (LearningInterest) -> Void
    
    var body: some View {
        CustomSectionView(header: category.displayName) {
            HFlow(alignment: .top, spacing: 8) {
                ForEach(interests, id: \.id) { interest in
                    InterestChip(
                        interest: interest,
                        isSelected: selectedInterests.contains(interest)
                    ) {
                        onToggleInterest(interest)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}

struct InterestChip: View {
    let interest: LearningInterest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            TagView(
                text: interest.title,
                systemImage: interest.iconName,
                color: .accent,
                size: .regular,
                style: isSelected ? .selected : .regular
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InterestsOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
