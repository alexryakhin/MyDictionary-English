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
    
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswerIndex: Int?
    @State private var showFeedback: Bool = false
    @State private var quizAnswers: [Int: Int] = [:]
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
        lessonContent(viewModel.lesson)
        .navigation(
            title: config.song.title,
            mode: .regular,
            showsBackButton: true
        )
        .sheet(item: $phraseCollectionForSheet) { collection in
            AddCollectionToDictionaryView(collection: collection)
        }
        .sheet(item: $selectedPhraseItem) { word in
            WordCollectionItemDetailsView(
                word: word,
                collection: viewModel.phraseWordCollection
            )
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.shouldNavigateToResults) { _, shouldNavigate in
            if shouldNavigate {
                let config = SongLessonResultsConfig(session: viewModel.currentSession, song: self.config.song)
                NavigationManager.shared.navigate(to: .songLessonResults(config))
            }
        }
    }
    
    // MARK: - Lesson Content
    
    private func lessonContent(_ lesson: AdaptedLesson) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                lessonOverviewSection(lesson)
                phrasesSection()
                grammarSection(lesson.grammarNuggets)
                cultureSection(lesson.cultureNotes)
                fillInBlanksSection(lesson.quiz.fillInBlanks)
                multipleChoiceSection(lesson.quiz.meaningMCQ)
                reflectionSection(lesson)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupedBackground()
    }
    
    // MARK: - Overview
    
    private func lessonOverviewSection(_ lesson: AdaptedLesson) -> some View {
        CustomSectionView(header: "Lesson Path", headerFontStyle: .large) {
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
            // Rule
            Text(nugget.rule)
                .font(.headline)
            
            // Example
            Text(nugget.example)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TagView(
                text: nugget.cefr.displayName,
                size: .small
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
    
    // MARK: - Culture Section
    
    private func cultureSection(_ notes: [CultureNote]) -> some View {
        CustomSectionView(header: "Cultural Notes", headerSubtitle: "Context that brings the lyrics to life.") {
            if notes.isEmpty {
                emptySectionPlaceholder("No cultural context provided.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        cultureCard(note)
                    }
                }
            }
        }
    }
    
    private func cultureCard(_ note: CultureNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text
            Text(note.text)
                .font(.body)
            
            TagView(
                text: note.cefr.displayName,
                size: .small
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
    
    // MARK: - Fill in the Blanks Section
    
    private func fillInBlanksSection(_ items: [FillInBlankItem]) -> some View {
        CustomSectionView(header: "Practice • Fill the Blank", headerSubtitle: "Test recall with lyric-based prompts.") {
            if items.isEmpty {
                emptySectionPlaceholder("Fill-in-the-blank practice will appear once available.")
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        fillInBlankCard(item: item, index: index)
                    }
                }
            }
        }
    }
    
    private func fillInBlankCard(item: FillInBlankItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.prompt)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(item.lyricReference)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { optionIndex, option in
                    Button(action: {
                        // Handle answer selection
                        quizAnswers[index] = optionIndex
                        let isCorrect = option == item.blankWord
                        viewModel.handle(.submitQuizAnswer(
                            questionIndex: index,
                            answerIndex: optionIndex,
                            isCorrect: isCorrect
                        ))
                    }) {
                        Text(option)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                quizAnswers[index] == optionIndex
                                    ? (option == item.blankWord ? Color.green : Color.red)
                                    : Color.secondarySystemGroupedBackground
                            )
                            .foregroundColor(
                                quizAnswers[index] == optionIndex ? .white : .primary
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(quizAnswers[index] != nil)
                }
            }
        }
        .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
    
    // MARK: - Multiple Choice Section
    
    private func multipleChoiceSection(_ items: [MCQItem]) -> some View {
        CustomSectionView(header: "Practice • Comprehension Quiz", headerSubtitle: "Choose the best answer to reinforce meaning.") {
            if items.isEmpty {
                emptySectionPlaceholder("Multiple-choice practice will appear once available.")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ProgressView(
                        value: Double(currentQuestionIndex + 1),
                        total: Double(items.count)
                    )
                    .progressViewStyle(.linear)

                    Text("Question \(currentQuestionIndex + 1) of \(items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if currentQuestionIndex < items.count {
                        multipleChoiceCard(
                            item: items[currentQuestionIndex],
                            questionIndex: currentQuestionIndex
                        )
                    }

                    questionNavigation(totalQuestions: items.count)
                }
            }
        }
    }
    
    private func multipleChoiceCard(item: MCQItem, questionIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question
            Text(item.question)
                .font(.headline)
                .padding(.bottom, 8)
            
            // Options
            ForEach(Array(item.options.enumerated()), id: \.offset) { optionIndex, option in
                multipleChoiceButton(
                    option: option,
                    optionIndex: optionIndex,
                    questionIndex: questionIndex,
                    correctAnswer: item.correctAnswer
                )
            }
            
            // Show feedback if answered
            if let selectedIndex = selectedAnswerIndex, showFeedback {
                let selectedOption = item.options[selectedIndex]
                let isCorrect = selectedOption == item.correctAnswer
                
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    if let explanation = item.explanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
    
    private func multipleChoiceButton(
        option: String,
        optionIndex: Int,
        questionIndex: Int,
        correctAnswer: String
    ) -> some View {
        let isSelected = selectedAnswerIndex == optionIndex
        let isCorrect = option == correctAnswer
        let isQuestionAnswered = quizAnswers[questionIndex] != nil
        
        return Button(action: {
            if !isQuestionAnswered {
                selectedAnswerIndex = optionIndex
                quizAnswers[questionIndex] = optionIndex
                showFeedback = true
                
                viewModel.handle(.submitQuizAnswer(
                    questionIndex: questionIndex,
                    answerIndex: optionIndex,
                    isCorrect: isCorrect
                ))
                
                HapticManager.shared.triggerImpact(style: isCorrect ? .medium : .light)
            }
        }) {
            HStack {
                Text(option)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(
                        isSelected
                            ? .white
                            : .primary
                    )
                
                Spacer()
                
                if isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected
                    ? (isCorrect ? Color.green : Color.red)
                    : Color.secondarySystemGroupedBackground
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isQuestionAnswered)
    }
    
    // MARK: - Question Navigation
    
    private func questionNavigation(totalQuestions: Int) -> some View {
        HStack {
            ActionButton("Previous", systemImage: "chevron.left", action: {
                if currentQuestionIndex > 0 {
                    withAnimation {
                        currentQuestionIndex -= 1
                        selectedAnswerIndex = quizAnswers[currentQuestionIndex]
                        showFeedback = quizAnswers[currentQuestionIndex] != nil
                    }
                }
            })
            .disabled(currentQuestionIndex == 0)
            
            ActionButton(
                currentQuestionIndex < totalQuestions - 1 ? "Next" : "Finish",
                systemImage: "chevron.right",
                action: {
                if currentQuestionIndex < totalQuestions - 1 {
                    withAnimation {
                        currentQuestionIndex += 1
                        selectedAnswerIndex = quizAnswers[currentQuestionIndex]
                        showFeedback = quizAnswers[currentQuestionIndex] != nil
                    }
                } else {
                    // Quiz completed
                    viewModel.handle(.markQuizComplete)
                    viewModel.handle(.navigateToResults)
                }
            })
        }
    }
    
    // MARK: - Reflection Section

    @ViewBuilder
    private func reflectionSection(_ lesson: AdaptedLesson) -> some View {
        let totalQuestions = lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count
        let answeredQuestions = viewModel.currentSession.quizAnswers.count
        let isReadyToFinish = totalQuestions == 0 || answeredQuestions >= totalQuestions

        CustomSectionView(header: "Reflect & Wrap-up", headerSubtitle: "Capture what resonated and continue your streak.") {
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
