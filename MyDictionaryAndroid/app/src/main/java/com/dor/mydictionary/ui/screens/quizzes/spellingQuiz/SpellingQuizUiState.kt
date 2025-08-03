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
    val error: String? = null
) 