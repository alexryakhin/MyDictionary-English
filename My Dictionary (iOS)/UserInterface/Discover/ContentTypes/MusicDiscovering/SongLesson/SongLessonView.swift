//
//  SongLessonView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import Flow

struct SongLessonConfig: Hashable {
    let song: Song
    let lesson: AdaptedLesson
    let session: MusicDiscoveringSession
    
    static func == (lhs: SongLessonConfig, rhs: SongLessonConfig) -> Bool {
        return lhs.session.id == rhs.session.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(session.id)
    }
}

struct SongLessonView: View {
    private let config: SongLessonConfig
    @StateObject private var viewModel: SongLessonViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var phraseCollectionForSheet: WordCollection?
    @State private var selectedPhraseItem: WordCollectionItem?
    
    init(config: SongLessonConfig) {
        self.config = config
        _viewModel = StateObject(
            wrappedValue: SongLessonViewModel(
                song: config.song,
                lesson: config.lesson,
                session: config.session
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                lessonOverviewSection(viewModel.lesson)
                phrasesSection()
                grammarSection(viewModel.lesson.grammarNuggets)
                cultureSection(viewModel.lesson.cultureNotes)
                fillInBlanksSection(viewModel.lesson.quiz.fillInBlanks)
                multipleChoiceSection(
                    viewModel.lesson.quiz.meaningMCQ,
                    questionOffset: viewModel.lesson.quiz.fillInBlanks.count
                )
                reflectionSection(viewModel.lesson)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupedBackground()
        .navigation(
            title: config.song.title,
            mode: .regular,
            showsBackButton: true
        )
        .sheet(item: $phraseCollectionForSheet) { collection in
            AddCollectionToDictionaryView(collection: collection) { result in
                viewModel.handle(.addDiscoveredWords(result.addedWords))
            }
        }
        .sheet(item: $selectedPhraseItem) { word in
            WordCollectionItemDetailsView(
                word: word,
                collection: viewModel.phraseWordCollection
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Overview
    
    private func lessonOverviewSection(_ lesson: AdaptedLesson) -> some View {
        CustomSectionView(
            header: "Lesson Path",
            headerFontStyle: .large
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Immerse yourself in **\(config.song.title)** by \(config.song.artist). This lesson guides you from lyrical meaning to cultural context before challenging you with active recall.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HFlow(spacing: 8) {
                    lessonTag(title: lesson.language.englishName, systemImage: "globe.europe.africa")
                    lessonTag(title: lesson.userLevel.rawValue.uppercased(), systemImage: "chart.line.uptrend.xyaxis")
                    lessonTag(title: "\(lesson.phrases.count) phrases", systemImage: "quote.bubble")
                    lessonTag(title: "\(lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count) practice", systemImage: "slider.horizontal.3")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func lessonTag(title: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(title)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.tertiarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Phrases Section

    @ViewBuilder
    private func phrasesSection() -> some View {
        let phraseItems = viewModel.phraseItems
        CustomSectionView(
            header: "Key Phrases",
            headerSubtitle: "Learn the expressions that shape the song’s story.",
            hPadding: .zero
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if phraseItems.isEmpty {
                    ContentUnavailableView(
                        Loc.WordCollections.noWordsFound,
                        systemImage: "magnifyingglass",
                        description: Text("No phrases available yet.")
                    )
                    .padding(.vertical, 24)
                } else {
                    ListWithDivider(phraseItems) { item in
                        WordCollectionItemRow(word: item) {
                            selectedPhraseItem = item
                        }
                    }
                }
            }
        } trailingContent: {
            HeaderButtonMenu(
                icon: viewModel.isTranslatingPhrases ? "timer" : "ellipsis",
                size: .small
            ) {
                Button {
                    phraseCollectionForSheet = viewModel.phraseWordCollection
                } label: {
                    Label(Loc.WordCollections.addToMyDictionary, systemImage: "plus.circle")
                }
                
                if viewModel.canTranslatePhrases {
                    Button {
                        Task {
                            await viewModel.translatePhrases()
                        }
                    } label: {
                        Label(Loc.WordCollections.translateDefinitions, systemImage: "globe")
                    }
                    .disabled(viewModel.isTranslatingPhrases)
                }
            }
        }
    }
    
    // MARK: - Grammar Section
    
    private func grammarSection(_ nuggets: [GrammarNugget]) -> some View {
        CustomSectionView(header: "Grammar Spotlight", headerSubtitle: "Notice these structures while you listen.") {
            if nuggets.isEmpty {
                emptySectionPlaceholder("No grammar highlights for this lesson.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(nuggets.enumerated()), id: \.offset) { _, nugget in
                        grammarCard(nugget)
                    }
                }
            }
        }
    }
    
    private func grammarCard(_ nugget: GrammarNugget) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(nugget.rule)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TagView(
                    text: nugget.cefr.displayName,
                    size: .small
                )
            }

            Text(nugget.example)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(nugget.explanation)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
    
    // MARK: - Culture Section
    
    private func cultureSection(_ note: String) -> some View {
        CustomSectionView(
            header: "Cultural Notes",
            headerSubtitle: "Context that brings the lyrics to life."
        ) {
            if note.isEmpty {
                emptySectionPlaceholder("No cultural context provided.")
            } else {
                Text(note)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Fill in the Blanks Section
    
    private func fillInBlanksSection(_ items: [FillInBlankItem]) -> some View {
        CustomSectionView(
            header: "Practice • Fill the Blank",
            headerSubtitle: "Test recall with lyric-based prompts."
        ) {
            if items.isEmpty {
                emptySectionPlaceholder("Fill-in-the-blank practice will appear once available.")
            } else {
                SongLesson.FillInBlankQuizView(
                    config: SongLesson.FillInBlankQuizConfig(
                        items: items,
                        initialAnswers: quizAnswersDictionary(
                            totalQuestions: items.count,
                            offset: 0,
                            type: .fillInBlank
                        ),
                        questionIndexOffset: 0,
                        onAnswer: { submission in
                            viewModel.handle(.submitQuizAnswer(submission))
                        },
                        onCompletion: { _ in
                            viewModel.handle(.saveSession)
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Multiple Choice Section
    
    private func multipleChoiceSection(_ items: [MCQItem], questionOffset: Int) -> some View {
        CustomSectionView(
            header: "Practice • Comprehension Quiz",
            headerSubtitle: "Choose the best answer to reinforce meaning."
        ) {
            if items.isEmpty {
                emptySectionPlaceholder("Multiple-choice practice will appear once available.")
            } else {
                SongLesson.ComprehensionQuizView(
                    config: SongLesson.ComprehensionQuizConfig(
                        items: items,
                        initialAnswers: quizAnswersDictionary(
                            totalQuestions: items.count,
                            offset: questionOffset,
                            type: .meaningMCQ
                        ),
                        questionIndexOffset: questionOffset,
                        onAnswer: { submission in
                            viewModel.handle(.submitQuizAnswer(submission))
                        },
                        onCompletion: { _ in
                            viewModel.handle(.saveSession)
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Reflection Section

    @ViewBuilder
    private func reflectionSection(_ lesson: AdaptedLesson) -> some View {
        let totalQuestions = lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count
        let answeredQuestions = viewModel.currentSession.quizAnswers.count
        let isReadyToFinish = totalQuestions == 0 || answeredQuestions >= totalQuestions

        CustomSectionView(
            header: "Reflect & Wrap-up",
            headerSubtitle: "Capture what resonated and continue your streak."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("When you finish the quizzes, tap **Finish** to save your progress and view lesson results.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if totalQuestions > 0 {
                    Text("Progress: \(answeredQuestions)/\(totalQuestions) questions answered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ActionButton("View Lesson Results", style: .borderedProminent) {
                    viewModel.handle(.markQuizComplete)
                    viewModel.handle(.navigateToResults)
                }
                .disabled(!isReadyToFinish)
            }
        }
    }
    
    // MARK: - Helpers

    private func quizAnswersDictionary(
        totalQuestions: Int,
        offset: Int,
        type: MusicDiscoveringSession.QuizAnswer.QuizType
    ) -> [Int: Int] {
        guard totalQuestions > 0 else { return [:] }
        var dictionary: [Int: Int] = [:]
        for answer in viewModel.currentSession.quizAnswers {
            guard answer.type == type else { continue }
            let relativeIndex = answer.questionIndex - offset
            guard relativeIndex >= 0, relativeIndex < totalQuestions else { continue }
            dictionary[relativeIndex] = answer.selectedAnswerIndex
        }
        return dictionary
    }

    private func emptySectionPlaceholder(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tertiarySystemGroupedBackground)
            .cornerRadius(12)
    }
}
