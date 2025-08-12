import SwiftUI

struct QuizzesView: View {

    typealias ViewModel = QuizzesViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Practice Settings Section
            if !viewModel.words.isEmpty {
                practiceSettingsSection
            }
            
            // Quiz Selection
            quizSelectionSection
        }
        .background(Color(.textBackgroundColor))
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }
    
    private var practiceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Word Count Setting
                HStack {
                    Text("Words per session:")
                        .frame(width: 120, alignment: .leading)
                    
                    Slider(
                        value: _viewModel.projectedValue.practiceWordCount,
                        in: 5...50,
                        step: 5
                    )
                    .frame(width: 200)
                    
                    Text("\(Int(viewModel.practiceWordCount))")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(width: 30)
                }
                
                // Hard Words Filter
                HStack {
                    Text("Practice hard words only:")
                        .frame(width: 120, alignment: .leading)
                    
                    Toggle("", isOn: _viewModel.projectedValue.showingHardWordsOnly)
                        .labelsHidden()
                        .disabled(!viewModel.hasHardWords)
                    
                    if !viewModel.hasHardWords {
                        Text("(No hard words available)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var quizSelectionSection: some View {
        VStack(spacing: 0) {
            if viewModel.words.count < 10 {
                insufficientWordsSection
            } else {
                quizListSection
            }
        }
    }
    
    private var insufficientWordsSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)
                
                Text(viewModel.words.isEmpty ? "Start Building Your Vocabulary!" : "Keep Adding Words!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.words.isEmpty ? 
                     "You need at least **10 words** in your list to start taking quizzes.\n\nCurrently you have **0 words**." :
                     "You need at least **10 words** in your list to start taking quizzes.\n\nCurrently you have **\(viewModel.words.count) words**.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button {
                    TabManager.shared.switchToTab(.words)
                } label: {
                    Label(viewModel.words.isEmpty ? "Add Your First Word" : "Add More Words", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(viewModel.words.isEmpty ? 
                     "Quizzes help you test your knowledge and reinforce learning!" :
                     "You're \(10 - viewModel.words.count) words away from unlocking quizzes!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.windowBackgroundColor))
    }

    @ViewBuilder
    private var quizListSection: some View {
        let selection = Binding {
            viewModel.selectedQuiz
        } set: { quiz in
            if let quiz {
                viewModel.handle(.selectQuiz(quiz))
            }
        }

        List(selection: selection) {
            ForEach(Quiz.allCases) { quiz in
                QuizzesListCellView(quiz: quiz)
                    .tag(quiz)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .navigationTitle("Quizzes")
        .onDisappear {
            viewModel.handle(.deselectQuiz)
        }
    }
}

#Preview {
    QuizzesView(viewModel: StateObject(wrappedValue: QuizzesViewModel()))
}
