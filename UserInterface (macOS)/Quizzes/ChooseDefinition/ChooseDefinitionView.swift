import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared
import Services

struct ChooseDefinitionView: PageView {

    typealias ViewModel = ChooseDefinitionViewModel

    var _viewModel = StateObject(wrappedValue: ChooseDefinitionViewModel())
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    var contentView: some View {
        if !viewModel.words.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 4) {
                    Text(viewModel.words[viewModel.correctAnswerIndex].word)
                        .font(.largeTitle)
                        .bold()
                    Text(viewModel.words[viewModel.correctAnswerIndex].partOfSpeech.rawValue)
                        .foregroundColor(.secondary)
                    SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                        viewModel.handle(.playWord)
                    }
                }

                Spacer()

                Text("Choose from the given definitions below")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(0..<3) { index in
                    Text(viewModel.words[index].definition)
                        .foregroundColor(.primary)
                        .frame(width: 300)
                        .clippedWithPaddingAndBackground(.surfaceColor)
                        .onTapGesture {
                            withAnimation {
                                viewModel.handle(.selectAnswer(index))
                                AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
                            }
                        }
                }

                if !viewModel.isCorrectAnswer {
                    Text("Incorrect. Try Again")
                        .foregroundStyle(.secondary)
                }

                Spacer()
                    .frame(height: 100)
            }
            .ignoresSafeArea()
            .navigationTitle("Choose Definition")
            .onAppear {
                viewModel.handle(.setRandomIndex)
                AnalyticsService.shared.logEvent(.definitionQuizOpened)
            }
        }
    }
}
