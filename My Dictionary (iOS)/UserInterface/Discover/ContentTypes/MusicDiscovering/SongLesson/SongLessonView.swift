//
//  SongLessonView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import Flow

struct SongLessonView: View {
    private let config: SongLessonConfig
    @StateObject private var ttsPlayer: TTSPlayer = .shared
    @StateObject private var viewModel: SongLessonViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
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
            LazyVStack(spacing: 24) {
                lessonOverviewSection(viewModel.lesson)
                cultureSection(viewModel.lesson.cultureNotes, languageCode: viewModel.lesson.language.rawValue)
                phrasesSection()
                grammarSection(viewModel.lesson.grammarNuggets)
                explanationsSection(viewModel.lesson.explanations)
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
        .onAppear {
            viewModel.lessonDidAppear()
        }
        .onDisappear {
            viewModel.lessonDidDisappear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Overview
    
    private func lessonOverviewSection(_ lesson: AdaptedLesson) -> some View {
        CustomSectionView(
            header: Loc.MusicDiscovering.Lesson.Overview.title,
            headerFontStyle: .large
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    LocalizedStringKey(
                        Loc.MusicDiscovering.Lesson.Overview.description(
                            config.song.title,
                            config.song.artist
                        )
                    )
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                HFlow(spacing: 8) {
                    lessonTag(title: lesson.language.englishName, systemImage: "globe.europe.africa")
                    lessonTag(title: lesson.userLevel.rawValue.uppercased(), systemImage: "chart.line.uptrend.xyaxis")
                    lessonTag(title: Loc.MusicDiscovering.Lesson.Overview.phrasesTag(lesson.phrases.count), systemImage: "quote.bubble")
                    lessonTag(title: Loc.MusicDiscovering.Lesson.Overview.practiceTag(lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count), systemImage: "slider.horizontal.3")
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
            header: Loc.MusicDiscovering.Lesson.Phrases.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Phrases.subtitle,
            hPadding: .zero
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if phraseItems.isEmpty {
                    ContentUnavailableView(
                        Loc.WordCollections.noWordsFound,
                        systemImage: "magnifyingglass",
                        description: Text(Loc.MusicDiscovering.Lesson.Phrases.empty)
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
        CustomSectionView(header: Loc.MusicDiscovering.Lesson.Grammar.header, headerSubtitle: Loc.MusicDiscovering.Lesson.Grammar.subtitle) {
            if nuggets.isEmpty {
                emptySectionPlaceholder(Loc.MusicDiscovering.Lesson.Grammar.empty)
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
    
    private func explanationsSection(_ items: [LyricExplanation]) -> some View {
        CustomSectionView(
            header: Loc.MusicDiscovering.Lesson.Explanations.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Explanations.subtitle
        ) {
            if items.isEmpty {
                emptySectionPlaceholder(Loc.MusicDiscovering.Lesson.Explanations.empty)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    let sortedIndices = items.sorted()
                    ForEach(sortedIndices.indices, id: \.self) { index in
                        let explanation = sortedIndices[index]
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(Loc.MusicDiscovering.Lesson.Explanations.lineNumber(explanation.lineNumber))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    viewModel.handle(.playCultureNotes(explanation.explanation))
                                } label: {
                                    Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                                        .font(.caption)
                                }
                                .disabled(ttsPlayer.isPlaying)
                            }

                            InteractiveText(
                                text: explanation.lyricLine,
                                font: .headline,
                                sourceLanguageCode: viewModel.lesson.language.rawValue
                            )

                            InteractiveText(
                                text: explanation.explanation,
                                font: .subheadline,
                                sourceLanguageCode: viewModel.lesson.language.rawValue
                            )
                        }
                        .padding(12)
                        .background(Color.tertiarySystemGroupedBackground)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func cultureSection(_ note: String, languageCode: String) -> some View {
        CustomSectionView(
            header: Loc.MusicDiscovering.Lesson.Culture.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Culture.subtitle
        ) {
            if note.isEmpty {
                emptySectionPlaceholder(Loc.MusicDiscovering.Lesson.Culture.empty)
            } else {
                InteractiveText(
                    text: note,
                    font: .body,
                    highlighted: false,
                    sourceLanguageCode: languageCode
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } trailingContent: {
            if note.isNotEmpty {
                HeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    viewModel.handle(.playCultureNotes(note))
                }
                .disabled(ttsPlayer.isPlaying)
            }
        }
    }

    // MARK: - Fill in the Blanks Section
    
    private func fillInBlanksSection(_ items: [FillInBlankItem]) -> some View {
        CustomSectionView(
            header: Loc.MusicDiscovering.Lesson.Practice.FillBlank.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Practice.FillBlank.subtitle
        ) {
            if items.isEmpty {
                emptySectionPlaceholder(Loc.MusicDiscovering.Lesson.Practice.FillBlank.empty)
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
            header: Loc.MusicDiscovering.Lesson.Practice.Comprehension.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Practice.Comprehension.subtitle
        ) {
            if items.isEmpty {
                emptySectionPlaceholder(Loc.MusicDiscovering.Lesson.Practice.Comprehension.empty)
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
            header: Loc.MusicDiscovering.Lesson.Reflection.header,
            headerSubtitle: Loc.MusicDiscovering.Lesson.Reflection.subtitle
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey(Loc.MusicDiscovering.Lesson.Reflection.instructions))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if totalQuestions > 0 {
                    Text(Loc.MusicDiscovering.Lesson.Reflection.progress(answeredQuestions, totalQuestions))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ActionButton(Loc.MusicDiscovering.Lesson.Reflection.ctaViewResults, style: .borderedProminent) {
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
