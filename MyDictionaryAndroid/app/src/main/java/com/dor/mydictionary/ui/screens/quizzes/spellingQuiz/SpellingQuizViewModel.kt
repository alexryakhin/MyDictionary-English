package com.dor.mydictionary.ui.screens.quizzes.spellingQuiz

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.QuizSessionManager
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordManager
import com.dor.mydictionary.services.WordProgressManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.*
import javax.inject.Inject

@HiltViewModel
class SpellingQuizViewModel @Inject constructor(
    private val wordManager: WordManager,
    private val quizSessionManager: QuizSessionManager,
    private val userStatsManager: UserStatsManager,
    private val wordProgressManager: WordProgressManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(SpellingQuizUiState())
    val uiState: StateFlow<SpellingQuizUiState> = _uiState.asStateFlow()

    private var quizWords: List<Word> = emptyList()
    private var currentSessionId: String? = null

    fun startQuiz() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Get practice settings
                val userStats = userStatsManager.getUserStats()
                val wordsPerSession = userStats.wordsPerSession
                val hardWordsOnly = userStats.practiceHardWordsOnly
                
                // Get words for quiz
                val availableWords = if (hardWordsOnly) {
                    wordManager.getHardWords()
                } else {
                    wordManager.getAllWords()
                }
                
                if (availableWords.isEmpty()) {
                    _uiState.update { 
                        it.copy(
                            error = "No words available for quiz",
                            isLoading = false
                        )
                    }
                    return@launch
                }
                
                // Select random words for the quiz
                quizWords = availableWords.shuffled().take(wordsPerSession)
                
                // Create quiz session
                currentSessionId = UUID.randomUUID().toString()
                
                _uiState.update { 
                    it.copy(
                        currentQuestionIndex = 0,
                        totalQuestions = quizWords.size,
                        score = 0,
                        progress = 0f,
                        isLoading = false
                    )
                }
                
                loadFirstWord()
                
            } catch (e: Exception) {
                Log.e("SpellingQuizViewModel", "startQuiz error: ${e.message}", e)
                _uiState.update { 
                    it.copy(
                        error = "Failed to start quiz: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun setUserInput(input: String) {
        _uiState.update { it.copy(userInput = input) }
    }

    fun submitAnswer() {
        val currentState = _uiState.value
        val currentWord = currentState.currentWord ?: return
        
        val userAnswer = currentState.userInput.trim()
        val isCorrect = userAnswer.equals(currentWord.wordItself, ignoreCase = true)
        
        _uiState.update { 
            it.copy(
                isAnswerCorrect = isCorrect,
                isWordRevealed = true,
                score = if (isCorrect) it.score + 1 else it.score
            )
        }
        
        // Update word progress
        viewModelScope.launch {
            try {
                if (isCorrect) {
                    wordProgressManager.incrementCorrectAnswers(currentWord.id)
                } else {
                    wordProgressManager.incrementIncorrectAnswers(currentWord.id)
                }
            } catch (e: Exception) {
                // Log error but don't show to user
                println("Failed to update word progress: ${e.message}")
            }
        }
    }

    fun skipWord() {
        val currentState = _uiState.value
        val currentWord = currentState.currentWord ?: return
        
        // Mark word as needing review
        viewModelScope.launch {
            try {
                wordProgressManager.markAsNeedsReview(currentWord.id)
            } catch (e: Exception) {
                println("Failed to mark word for review: ${e.message}")
            }
        }
        
        loadNextWord()
    }

    fun loadFirstWord() {
        try {
            if (quizWords.isNotEmpty()) {
                val firstWord = quizWords[0]
                _uiState.update { 
                    it.copy(
                        currentWord = firstWord,
                        currentQuestionIndex = 0,
                        userInput = "",
                        isWordRevealed = false,
                        isAnswerCorrect = null,
                        progress = 1f / quizWords.size
                    )
                }
            } else {
                Log.w("SpellingQuizViewModel", "No quiz words available")
                _uiState.update { 
                    it.copy(
                        error = "No words available for quiz",
                        isLoading = false
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("SpellingQuizViewModel", "loadFirstWord error: ${e.message}", e)
            _uiState.update { 
                it.copy(
                    error = "Failed to load first word: ${e.message}",
                    isLoading = false
                )
            }
        }
    }

    fun loadNextWord() {
        val currentState = _uiState.value
        val nextIndex = currentState.currentQuestionIndex + 1
        
        if (nextIndex >= quizWords.size) {
            // Quiz is complete
            completeQuiz()
        } else {
            val nextWord = quizWords[nextIndex]
            _uiState.update { 
                it.copy(
                    currentWord = nextWord,
                    currentQuestionIndex = nextIndex,
                    userInput = "",
                    isWordRevealed = false,
                    isAnswerCorrect = null,
                    progress = (nextIndex + 1).toFloat() / quizWords.size
                )
            }
        }
    }

    private fun completeQuiz() {
        val currentState = _uiState.value
        
        viewModelScope.launch {
            try {
                // Save quiz session
                currentSessionId?.let { sessionId ->
                    quizSessionManager.saveQuizSession(
                        id = sessionId,
                        quizType = "Spelling Quiz",
                        totalQuestions = currentState.totalQuestions,
                        correctAnswers = currentState.score,
                        timestamp = Date()
                    )
                }
                
                // Update user stats
                userStatsManager.incrementQuizzesCompleted()
                userStatsManager.updateStreak()
                
                _uiState.update { 
                    it.copy(isQuizComplete = true)
                }
                
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to complete quiz: ${e.message}")
                }
            }
        }
    }

    fun finishQuiz() {
        // Reset state for potential new quiz
        _uiState.update { 
            it.copy(
                currentWord = null,
                userInput = "",
                currentQuestionIndex = 0,
                totalQuestions = 0,
                score = 0,
                progress = 0f,
                isWordRevealed = false,
                isAnswerCorrect = null,
                isQuizComplete = false
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
} 