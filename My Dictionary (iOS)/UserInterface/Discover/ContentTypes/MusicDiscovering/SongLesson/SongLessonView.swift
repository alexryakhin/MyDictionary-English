//
//  SongLessonView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

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
    
    @State private var selectedTab: LessonTab = .phrases
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswerIndex: Int?
    @State private var showFeedback: Bool = false
    @State private var quizAnswers: [Int: Int] = [:]
    
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
    
    enum LessonTab: String, CaseIterable {
        case phrases = "Phrases"
        case grammar = "Grammar"
        case culture = "Culture"
        case fillInBlanks = "Fill-in"
        case multipleChoice = "Quiz"
        
        var icon: String {
            switch self {
            case .phrases: return "quote.bubble"
            case .grammar: return "book"
            case .culture: return "globe"
            case .fillInBlanks: return "text.insert"
            case .multipleChoice: return "questionmark.circle"
            }
        }
    }
    
    var body: some View {
        lessonContent(viewModel.lesson)
        .navigation(
            title: config.song.title,
            mode: .inline
        )
        .onChange(of: viewModel.shouldNavigateToResults) { _, shouldNavigate in
            if shouldNavigate {
                let config = SongLessonResultsConfig(session: viewModel.currentSession, song: self.config.song)
                NavigationManager.shared.navigate(to: .songLessonResults(config))
            }
        }
    }
    
    // MARK: - Lesson Content
    
    private func lessonContent(_ lesson: AdaptedLesson) -> some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .phrases:
                        phrasesSection(lesson.phrases)
                    case .grammar:
                        grammarSection(lesson.grammarNuggets)
                    case .culture:
                        cultureSection(lesson.cultureNotes)
                    case .fillInBlanks:
                        fillInBlanksSection(lesson.quiz.fillInBlanks)
                    case .multipleChoice:
                        multipleChoiceSection(lesson.quiz.meaningMCQ)
                    }
                }
                .padding()
            }
            .groupedBackground()
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LessonTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.secondarySystemGroupedBackground)
    }
    
    private func tabButton(_ tab: LessonTab) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                Text(tab.rawValue)
            }
            .font(.subheadline)
            .fontWeight(selectedTab == tab ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                selectedTab == tab
                    ? Color.accentColor
                    : Color.tertiarySystemGroupedBackground
            )
            .foregroundColor(selectedTab == tab ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Phrases Section
    
    private func phrasesSection(_ phrases: [LessonPhrase]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(phrases.enumerated()), id: \.offset) { index, phrase in
                phraseCard(phrase)
            }
        }
    }
    
    private func phraseCard(_ phrase: LessonPhrase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text
            Text(phrase.text)
                .font(.headline)
            
            // Translation
            Text(phrase.meaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Example
            if !phrase.example.isEmpty {
                Text(phrase.example)
                    .font(.caption)
                    .foregroundColor(.secondaryLabel)
                    .italic()
                    .padding(.top, 4)
            }
            
            // CEFR Badge
            Text(phrase.cefr)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Grammar Section
    
    private func grammarSection(_ nuggets: [GrammarNugget]) -> some View {
        LazyVStack(spacing: 12) {
            if nuggets.isEmpty {
                Text("No grammar rules available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(nuggets.enumerated()), id: \.offset) { index, nugget in
                    grammarCard(nugget)
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
            
            // CEFR Badge (optional)
            if let cefr = nugget.cefr {
                Text(cefr)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Culture Section
    
    private func cultureSection(_ notes: [CultureNote]) -> some View {
        LazyVStack(spacing: 12) {
            if notes.isEmpty {
                Text("No culture notes available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    cultureCard(note)
                }
            }
        }
    }
    
    private func cultureCard(_ note: CultureNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text
            Text(note.text)
                .font(.body)
            
            // CEFR Badge (optional)
            if let cefr = note.cefr {
                Text(cefr)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Fill in the Blanks Section
    
    private func fillInBlanksSection(_ items: [FillInBlankItem]) -> some View {
        LazyVStack(spacing: 16) {
            if items.isEmpty {
                Text("No fill-in-the-blank questions available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    fillInBlankCard(item: item, index: index)
                }
                
                // Complete button
                if !items.isEmpty {
                    ActionButton(
                        "Complete Fill-in-the-Blanks",
                        style: .borderedProminent
                    ) {
                        // All fill-in-the-blanks completed
                        selectedTab = .multipleChoice
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func fillInBlankCard(item: FillInBlankItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question \(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Line \(item.line): Fill in the blank with '\(item.blankWord)'")
                .font(.subheadline)
            
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
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Multiple Choice Section
    
    private func multipleChoiceSection(_ items: [MCQItem]) -> some View {
        LazyVStack(spacing: 16) {
            if items.isEmpty {
                Text("No multiple choice questions available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(
                        value: Double(currentQuestionIndex + 1),
                        total: Double(items.count)
                    )
                    .progressViewStyle(.linear)
                    
                    Text("Question \(currentQuestionIndex + 1) of \(items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Current question
                if currentQuestionIndex < items.count {
                    multipleChoiceCard(
                        item: items[currentQuestionIndex],
                        questionIndex: currentQuestionIndex
                    )
                }
                
                // Navigation buttons
                questionNavigation(totalQuestions: items.count)
            }
        }
    }
    
    private func multipleChoiceCard(item: MCQItem, questionIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
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
            Button(action: {
                if currentQuestionIndex > 0 {
                    withAnimation {
                        currentQuestionIndex -= 1
                        selectedAnswerIndex = quizAnswers[currentQuestionIndex]
                        showFeedback = quizAnswers[currentQuestionIndex] != nil
                    }
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .padding()
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(8)
            }
            .disabled(currentQuestionIndex == 0)
            
            Spacer()
            
            Button(action: {
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
            }) {
                HStack {
                    Text(currentQuestionIndex < totalQuestions - 1 ? "Next" : "Finish")
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        let song = Song(
            id: "1",
            title: "Sample Song",
            artist: "Sample Artist",
            album: "Sample Album",
            duration: 180,
            serviceId: "1",
            cefrLevel: .b1
        )
        
        let lesson = AdaptedLesson(
            songId: song.id,
            language: .english,
            phrases: [
                LessonPhrase(
                    text: "We keep dancing through the night",
                    meaning: "We continue dancing all night long",
                    cefr: "B1",
                    example: "They kept dancing through the night despite the rain.",
                    audioPrompt: nil
                )
            ],
            grammarNuggets: [
                GrammarNugget(
                    rule: "Use present continuous to describe ongoing actions.",
                    example: "We are dancing right now.",
                    cefr: "A2"
                )
            ],
            cultureNotes: [
                CultureNote(
                    text: "This song references festivals common in summer along the coast.",
                    cefr: "B1"
                )
            ],
            quiz: AdaptedQuiz(
                fillInBlanks: [
                    FillInBlankItem(
                        line: 12,
                        blankWord: "dancing",
                        options: ["dancing", "sleeping", "talking", "running"]
                    )
                ],
                meaningMCQ: [
                    MCQItem(
                        question: "What does 'through the night' mean in the song?",
                        correctAnswer: "For the entire night",
                        options: [
                            "At some point in the night",
                            "For the entire night",
                            "Before the night",
                            "After the night"
                        ],
                        explanation: "The phrase 'through the night' expresses continuity across the whole night."
                    )
                ],
                generatedAt: Date()
            ),
            adaptedAt: Date(),
            userLevel: .b1
        )
        
        let session = MusicDiscoveringSession(song: song)
        let config = SongLessonConfig(song: song, lesson: lesson, session: session)
        
        SongLessonView(config: config)
    }
}

