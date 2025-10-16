//
//  OnboardingUserTypeView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingUserTypeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Image
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.whichBestDescribesYou)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Content
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(UserType.allCases, id: \.self) { userType in
                        SelectableCard(
                            title: userType.displayName,
                            subtitle: userType.description,
                            icon: userType.icon,
                            isSelected: viewModel.selectedUserType == userType
                        ) {
                            viewModel.selectedUserType = userType
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .ageGroup)
            }
            .disabled(viewModel.selectedUserType == nil)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

