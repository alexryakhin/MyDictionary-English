//
//  OnboardingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            VStack {
                Text("Welcome to\nMy Dictionary")
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.top, 70)

                Spacer()

                VStack(alignment: .leading, spacing: 25) {
                    ForEach(onboardingCases, id: \.self) { oCase in
                        HStack {
                            Image(systemName: oCase.icon)
                                .frame(sideLength: 40)
                                .foregroundColor(.accentColor)
                                .padding(16)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(oCase.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(oCase.subTitle)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(16)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .cornerRadius(12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)

                Spacer().frame(height: 40)
            }
        }
    }

    struct OnboardingCase: Hashable {
        var icon: String
        var title: String
        var subTitle: String
    }

    private var onboardingCases = [
        OnboardingCase(
            icon: "text.justify",
            title: "Your own list of words",
            subTitle: "Note any words you want, write your own definitions and examples"),
        OnboardingCase(
            icon: "network",
            title: "Get definitions from the Internet",
            subTitle: "Some words might mean totally different thing!"),
        OnboardingCase(
            icon: "a.magnify",
            title: "Quizzes",
            subTitle: "Expand your vocabulary with quizzes from your word list.")
    ]
}
