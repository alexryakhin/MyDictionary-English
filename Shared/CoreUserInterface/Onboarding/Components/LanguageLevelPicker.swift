//
//  LanguageLevelPicker.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct LanguageLevelPicker: View {
        let language: InputLanguage
        @Binding var selectedLevel: CEFRLevel
        let onSave: () -> Void
        @Environment(\.dismiss) var dismiss

        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)
                    VStack(spacing: 8) {
                        Text(language.displayName)
                            .font(.title.bold())
                        Text(Loc.Onboarding.selectProficiencyLevel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 12) {
                        ForEach(CEFRLevel.allCases, id: \.self) { level in
                            Button(action: { selectedLevel = level }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(level.rawValue)
                                            .font(.headline)
                                        Spacer()
                                        if selectedLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            selectedLevel == level
                                            ? Color.accentColor.opacity(0.1)
                                            : Color.secondarySystemGroupedBackground
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedLevel == level
                                                ? Color.accentColor
                                                : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .groupedBackground()
            .safeAreaBarIfAvailable(edge: .top, alignment: .leading) {
                HeaderButton(Loc.Actions.cancel) {
                    dismiss()
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .safeAreaBarIfAvailable {
                ActionButton(
                    Loc.Actions.add,
                    style: .borderedProminent,
                    action: onSave
                )
                .padding(vertical: 12, horizontal: 16)
            }
        }
    }
}
