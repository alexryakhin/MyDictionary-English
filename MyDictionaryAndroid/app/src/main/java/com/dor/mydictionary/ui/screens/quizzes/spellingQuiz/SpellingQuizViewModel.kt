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

    private var quizWords: MutableList<Word> = mutableListOf()
    private var originalWords: List<Word> = emptyList()
    private var currentSessionId: String? = null
    private var sessionStartTime: Date = Date()

    fun startQuiz() {
        viewModelScope.launch {
            try {
                Log.d("SpellingQuizViewModel", "Starting quiz...")
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Get practice settings
                Log.d("SpellingQuizViewModel", "Getting user stats...")
                val userStats = userStatsManager.getUserStats()
                val wordsPerSession = userStats.wordsPerSession
                val hardWordsOnly = userStats.practiceHardWordsOnly
                
                Log.d("SpellingQuizViewModel", "Getting words... wordsPerSession=$wordsPerSession, hardWordsOnly=$hardWordsOnly")
                // Get words for quiz
                val availableWords = if (hardWordsOnly) {
                    wordManager.getHardWords()
                } else {
                    wordManager.getAllWords()
                }
                
                Log.d("SpellingQuizViewModel", "Available words count: ${availableWords.size}")
                
                if (availableWords.isEmpty()) {
                    Log.w("SpellingQuizViewModel", "No words available for quiz")
                    _uiState.update { 
                        it.copy(
                            error = "No words available for quiz",
                            isLoading = false
                        )
                    }
                    return@launch
                }
                
                // Store original words and select random words for the quiz
                originalWords = availableWords
                quizWords = availableWords.shuffled().take(wordsPerSession).toMutableList()
                
                Log.d("SpellingQuizViewModel", "Selected ${quizWords.size} words for quiz")
                
                // Create quiz session
                currentSessionId = UUID.randomUUID().toString()
                sessionStartTime = Date()
                
                _uiState.update { 
                    it.copy(
                        currentQuestionIndex = 0,
                        totalQuestions = quizWords.size,
                        score = 0,
                        progress = 0f,
                        correctAnswers = 0,
                        currentStreak = 0,
                        bestStreak = 0,
                        attemptCount = 0,
                        isShowingCorrectAnswer = false,
                        isShowingHint = false,
                        wordsPlayed = emptyList(),
                        correctWordIds = emptyList(),
                        isLoading = false
                    )
                }
                
                Log.d("SpellingQuizViewModel", "Loading first word...")
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
        
        if (isCorrect) {
            // Correct answer
            val newAttemptCount = currentState.attemptCount
            val newCurrentStreak = currentState.currentStreak + 1
            val newBestStreak = maxOf(currentState.bestStreak, newCurrentStreak)
            val newCorrectAnswers = currentState.correctAnswers + 1
            
            // Calculate score with attempt bonus (bonus for fewer attempts)
            val attemptBonus = maxOf(0, 3 - newAttemptCount) * 10
            val newScore = currentState.score + 100 + attemptBonus
            
            _uiState.update { 
                it.copy(
                    isAnswerCorrect = true,
                    isShowingCorrectAnswer = true,
                    attemptCount = 0,
                    correctAnswers = newCorrectAnswers,
                    currentStreak = newCurrentStreak,
                    bestStreak = newBestStreak,
                    score = newScore,
                    isShowingHint = false,
                    wordsPlayed = it.wordsPlayed + currentWord,
                    correctWordIds = it.correctWordIds + currentWord.id
                )
            }
            
            // Update word progress
            viewModelScope.launch {
                try {
                    wordProgressManager.incrementCorrectAnswers(currentWord.id)
                } catch (e: Exception) {
                    Log.e("SpellingQuizViewModel", "Failed to update word progress: ${e.message}")
                }
            }
        } else {
            // Incorrect answer
            val newAttemptCount = currentState.attemptCount + 1
            val newCurrentStreak = 0 // Reset streak on wrong answer
            
            _uiState.update { 
                it.copy(
                    isAnswerCorrect = false,
                    attemptCount = newAttemptCount,
                    currentStreak = newCurrentStreak,
                    isShowingHint = newAttemptCount >= 2
                )
            }
            
            // After 3 attempts, mark word as needs review
            if (newAttemptCount >= 3) {
                viewModelScope.launch {
                    try {
                        wordProgressManager.markAsNeedsReview(currentWord.id)
                    } catch (e: Exception) {
                        Log.e("SpellingQuizViewModel", "Failed to mark word for review: ${e.message}")
                    }
                }
            }
        }
    }

    fun skipWord() {
        val currentState = _uiState.value
        val currentWord = currentState.currentWord ?: return
        
        // Mark skipped word as needs review
        viewModelScope.launch {
            try {
                wordProgressManager.markAsNeedsReview(currentWord.id)
            } catch (e: Exception) {
                Log.e("SpellingQuizViewModel", "Failed to mark word for review: ${e.message}")
            }
        }
        
        // Remove word from list (don't move to end)
        val wordIndex = quizWords.indexOfFirst { it.id == currentWord.id }
        if (wordIndex != -1) {
            quizWords.removeAt(wordIndex)
        }
        
        // Penalty for skipping
        val newScore = maxOf(0, currentState.score - 25)
        val newCurrentStreak = 0 // Reset streak on skip
        
        _uiState.update { 
            it.copy(
                score = newScore,
                currentStreak = newCurrentStreak,
                userInput = "",
                attemptCount = 0,
                isShowingCorrectAnswer = false,
                isShowingHint = false
            )
        }
        
        // Check if quiz is complete
        if (quizWords.isEmpty()) {
            _uiState.update { it.copy(currentWord = null, isQuizComplete = true) }
            completeQuiz()
        } else {
            // Get next word
            val nextWord = quizWords.random()
            _uiState.update { 
                it.copy(
                    currentWord = nextWord,
                    currentQuestionIndex = it.currentQuestionIndex + 1,
                    progress = (it.currentQuestionIndex + 1).toFloat() / it.totalQuestions
                )
            }
        }
    }

    fun loadNextWord() {
        val currentState = _uiState.value
        val currentWord = currentState.currentWord ?: return
        
        // Remove the current word from the list
        val wordIndex = quizWords.indexOfFirst { it.id == currentWord.id }
        if (wordIndex != -1) {
            quizWords.removeAt(wordIndex)
        }
        
        // Clear the answer field and reset state
        _uiState.update { 
            it.copy(
                userInput = "",
                isShowingCorrectAnswer = false,
                attemptCount = 0,
                isShowingHint = false
            )
        }
        
        // Move to next word or complete quiz
        if (quizWords.isNotEmpty()) {
            val nextWord = quizWords.random()
            _uiState.update { 
                it.copy(
                    currentWord = nextWord,
                    currentQuestionIndex = it.currentQuestionIndex + 1,
                    progress = (it.currentQuestionIndex + 1).toFloat() / it.totalQuestions
                )
            }
        } else {
            _uiState.update { it.copy(currentWord = null, isQuizComplete = true) }
            completeQuiz()
        }
    }

    fun restartQuiz() {
        // Reset all game state
        val limitedWords = originalWords.shuffled().take(_uiState.value.totalQuestions)
        quizWords = limitedWords.toMutableList()
        
        _uiState.update { 
            it.copy(
                currentWord = quizWords.random(),
                userInput = "",
                isAnswerCorrect = null,
                attemptCount = 0,
                correctAnswers = 0,
                totalQuestions = limitedWords.size,
                score = 0,
                wordsPlayed = emptyList(),
                correctWordIds = emptyList(),
                isQuizComplete = false,
                isShowingHint = false,
                isShowingCorrectAnswer = false,
                currentStreak = 0,
                currentQuestionIndex = 0,
                progress = 0f
            )
        }
        
        sessionStartTime = Date()
    }

    private fun completeQuiz() {
        val currentState = _uiState.value
        
        viewModelScope.launch {
            try {
                // Save quiz session
                currentSessionId?.let { sessionId ->
                    val duration = Date().time - sessionStartTime.time
                    val accuracy = if (currentState.totalQuestions > 0) {
                        currentState.correctAnswers.toDouble() / currentState.totalQuestions.toDouble()
                    } else 0.0
                    
                    quizSessionManager.saveQuizSession(
                        id = sessionId,
                        quizType = "Spelling Quiz",
                        totalQuestions = currentState.totalQuestions,
                        correctAnswers = currentState.correctAnswers,
                        timestamp = Date()
                    )
                }
                
                // Update user stats
                userStatsManager.incrementQuizzesCompleted()
                userStatsManager.updateStreak()
                
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
                isQuizComplete = false,
                attemptCount = 0,
                isShowingCorrectAnswer = false,
                correctAnswers = 0,
                wordsPlayed = emptyList(),
                correctWordIds = emptyList(),
                isShowingHint = false,
                currentStreak = 0,
                bestStreak = 0
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun loadFirstWord() {
        try {
            Log.d("SpellingQuizViewModel", "loadFirstWord: quizWords.size=${quizWords.size}")
            if (quizWords.isNotEmpty()) {
                val firstWord = quizWords[0]
                Log.d("SpellingQuizViewModel", "loadFirstWord: firstWord=${firstWord.wordItself}")
                _uiState.update { 
                    it.copy(
                        currentWord = firstWord,
                        currentQuestionIndex = 0,
                        userInput = "",
                        isWordRevealed = false,
                        isAnswerCorrect = null,
                        progress = 1f / quizWords.size,
                        attemptCount = 0,
                        isShowingCorrectAnswer = false,
                        isShowingHint = false
                    )
                }
                Log.d("SpellingQuizViewModel", "loadFirstWord: State updated successfully")
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
} 