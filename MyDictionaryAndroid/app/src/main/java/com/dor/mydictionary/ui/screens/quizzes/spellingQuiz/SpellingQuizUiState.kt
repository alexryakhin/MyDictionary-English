package com.dor.mydictionary.ui.screens.quizzes.spellingQuiz

import com.dor.mydictionary.core.Word

data class SpellingQuizUiState(
    val currentWord: Word? = null,
    val userInput: String = "",
    val currentQuestionIndex: Int = 0,
    val totalQuestions: Int = 0,
    val score: Int = 0,
    val progress: Float = 0f,
    val isWordRevealed: Boolean = false,
    val isAnswerCorrect: Boolean? = null,
    val isQuizComplete: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    
    // Game state properties (matching iOS)
    val attemptCount: Int = 0,
    val isShowingCorrectAnswer: Boolean = false,
    val correctAnswers: Int = 0,
    val wordsPlayed: List<Word> = emptyList(),
    val correctWordIds: List<String> = emptyList(),
    val isShowingHint: Boolean = false,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0
) 