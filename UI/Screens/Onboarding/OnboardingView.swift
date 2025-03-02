import SwiftUI

struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            VStack {
                Text("Welcome to\nMy Dictionary")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 35, weight: .bold))
                    .padding(.top, 70)

                Spacer()

                VStack(alignment: .leading, spacing: 25) {
                    ForEach(onboardingCases, id: \.self) { oCase in
                        HStack {
                            Image(systemName: oCase.icon)
                                .foregroundColor(.accentColor)
                                .font(.system(size: 40))
                                .frame(width: 40, height: 40)
                                .padding()
                            VStack(alignment: .leading, spacing: 5) {
                                Text(oCase.title)
                                    .font(.headline)
                                Text(oCase.subTitle)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Continue")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(25)
                }

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

#Preview {
    OnboardingView()
}
