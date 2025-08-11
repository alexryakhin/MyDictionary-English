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

    fun startQuiz(wordsPerSession: Int = 10, hardWordsOnly: Boolean = false) {
        _uiState.update { it.copy(isLoading = true, error = null) }
        
        viewModelScope.launch {
            try {
                Log.d("SpellingQuizViewModel", "Starting quiz with $wordsPerSession words, hardWordsOnly: $hardWordsOnly")
                
                // Get available words based on hard words setting
                val allAvailableWords = wordManager.getAllWords()
                val filteredWords = if (hardWordsOnly) {
                    allAvailableWords.filter { it.difficultyLevel == 2 }
                } else {
                    allAvailableWords
                }
                
                if (filteredWords.isEmpty()) {
                    _uiState.update { 
                        it.copy(
                            error = if (hardWordsOnly) {
                                "No words need review yet"
                            } else {
                                "No words available for quiz"
                            },
                            isLoading = false
                        )
                    }
                    return@launch
                }
                
                // Select random words for the quiz
                originalWords = filteredWords
                val wordsToTake = if (hardWordsOnly) minOf(wordsPerSession, filteredWords.size) else wordsPerSession
                quizWords = filteredWords.shuffled().take(wordsToTake).toMutableList()
                
                Log.d("SpellingQuizViewModel", "Selected ${quizWords.size} words for quiz")
                
                // Create quiz session
                currentSessionId = UUID.randomUUID().toString()
                sessionStartTime = Date()
                
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        currentWord = null,
                        userInput = "",
                        currentQuestionIndex = 0,
                        totalQuestions = quizWords.size,
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
                        bestStreak = 0,
                        accuracyContributions = emptyMap()
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
            
            // Calculate accuracy contribution based on attempts
            val accuracyContribution = when (newAttemptCount) {
                0 -> 1.0 // First attempt: 100% accuracy
                1 -> 0.75 // Second attempt: 75% accuracy (25% reduction)
                2 -> 0.5 // Third attempt: 50% accuracy (50% reduction)
                else -> 0.5 // Any more attempts: 50% accuracy
            }
            
            // Debug logging for accuracy contribution
            Log.d("SpellingQuizViewModel", "Word ${currentWord.wordItself}: attempts=$newAttemptCount, contribution=$accuracyContribution")
            
            // Calculate score (always +100 for correct answers)
            val newScore = currentState.score + 100
            
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
                    correctWordIds = it.correctWordIds + currentWord.id,
                    accuracyContributions = it.accuracyContributions + (currentWord.id to accuracyContribution)
                )
            }
            
            // Update word progress (this will also update difficulty level)
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
                    // DON'T add to wordsPlayed here - only when answered correctly, skipped, or failed
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
                
                // Add word to accuracy contributions with 0% accuracy (failed after 3 attempts)
                _uiState.update { 
                    it.copy(
                        wordsPlayed = it.wordsPlayed + currentWord, // Add to played list when failed
                        accuracyContributions = it.accuracyContributions + (currentWord.id to 0.0)
                    )
                }
                
                // Debug logging for failed word
                Log.d("SpellingQuizViewModel", "Word ${currentWord.wordItself}: FAILED after 3 attempts, contribution=0.0")
            } else {
                // Record incorrect attempt
                viewModelScope.launch {
                    try {
                        wordProgressManager.incrementIncorrectAnswers(currentWord.id)
                    } catch (e: Exception) {
                        Log.e("SpellingQuizViewModel", "Failed to record incorrect attempt: ${e.message}")
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
        
        // Update quiz score - subtract 2 points for skipping
        val newScore = currentState.score - 2
        val newCurrentStreak = 0 // Reset streak on skip
        
        _uiState.update { 
            it.copy(
                score = newScore,
                currentStreak = newCurrentStreak,
                userInput = "",
                attemptCount = 0,
                isShowingCorrectAnswer = false,
                isShowingHint = false,
                wordsPlayed = it.wordsPlayed + currentWord, // Add word to played list when skipped
                accuracyContributions = it.accuracyContributions + (currentWord.id to 0.0) // 0% accuracy for skipped words
            )
        }
        
        // Debug logging for skipped word
        Log.d("SpellingQuizViewModel", "Word ${currentWord.wordItself}: SKIPPED, contribution=0.0")
        
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
                // Calculate actual duration and accuracy
                val duration = (Date().time - sessionStartTime.time) / 1000.0 // Convert to seconds
                val accuracy = if (currentState.wordsPlayed.isNotEmpty()) {
                    // Calculate accuracy based on contributions
                    val totalAccuracyContribution = currentState.accuracyContributions.values.sum()
                    val averageAccuracy = totalAccuracyContribution / currentState.wordsPlayed.size
                    averageAccuracy
                } else 0.0
                
                // Debug logging
                Log.d("SpellingQuizViewModel", "Quiz completion: correctAnswers=${currentState.correctAnswers}, wordsPlayed=${currentState.wordsPlayed.size}, accuracy=$accuracy, score=${currentState.score}")
                Log.d("SpellingQuizViewModel", "Accuracy contributions: ${currentState.accuracyContributions}")
                Log.d("SpellingQuizViewModel", "Accuracy calculation: totalContribution=${currentState.accuracyContributions.values.sum()}, wordsPlayed=${currentState.wordsPlayed.size}, finalAccuracy=$accuracy")
                Log.d("SpellingQuizViewModel", "Duration calculation: sessionStartTime=$sessionStartTime, endTime=${Date()}, duration=${duration} seconds (${duration/60.0} minutes)")
                
                // Save quiz session with actual data
                currentSessionId?.let { sessionId ->
                    quizSessionManager.saveQuizSession(
                        id = sessionId,
                        quizType = "spelling",
                        totalQuestions = currentState.wordsPlayed.size, // Use words actually played
                        correctAnswers = currentState.correctAnswers,
                        timestamp = Date(),
                        duration = duration,
                        accuracy = accuracy,
                        score = currentState.score, // Pass the actual score
                        wordsPracticed = currentState.wordsPlayed.map { it.id }
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
                bestStreak = 0,
                accuracyContributions = emptyMap()
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun saveCurrentProgress() {
        val currentState = _uiState.value
        
        // Only save if quiz is in progress and has words played
        if (!currentState.isQuizComplete && currentState.wordsPlayed.isNotEmpty()) {
            Log.d("SpellingQuizViewModel", "Early exit detected: saving current progress")
            viewModelScope.launch {
                try {
                    // Calculate actual duration and accuracy
                    val duration = (Date().time - sessionStartTime.time) / 1000.0 // Convert to seconds
                    val accuracy = if (currentState.wordsPlayed.isNotEmpty()) {
                        // Calculate accuracy based on contributions
                        val totalAccuracyContribution = currentState.accuracyContributions.values.sum()
                        val averageAccuracy = totalAccuracyContribution / currentState.wordsPlayed.size
                        averageAccuracy
                    } else 0.0
                    
                    // Debug logging
                    Log.d("SpellingQuizViewModel", "Early exit: correctAnswers=${currentState.correctAnswers}, wordsPlayed=${currentState.wordsPlayed.size}, accuracy=$accuracy, score=${currentState.score}")
                    Log.d("SpellingQuizViewModel", "Duration calculation: sessionStartTime=$sessionStartTime, endTime=${Date()}, duration=${duration} seconds (${duration/60.0} minutes)")
                    
                    // Save quiz session with current data
                    currentSessionId?.let { sessionId ->
                        quizSessionManager.saveQuizSession(
                            id = sessionId,
                            quizType = "spelling",
                            totalQuestions = currentState.wordsPlayed.size, // Use words actually played
                            correctAnswers = currentState.correctAnswers,
                            timestamp = Date(),
                            duration = duration,
                            accuracy = accuracy,
                            score = currentState.score, // Pass the actual score
                            wordsPracticed = currentState.wordsPlayed.map { it.id }
                        )
                    }
                    
                    // Update user stats
                    userStatsManager.incrementQuizzesCompleted()
                    userStatsManager.updateStreak()
                    
                } catch (e: Exception) {
                    Log.e("SpellingQuizViewModel", "Failed to save current progress: ${e.message}", e)
                }
            }
        }
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