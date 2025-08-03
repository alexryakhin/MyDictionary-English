package com.dor.mydictionary.ui.screens.quizzes.chooseDefinitionQuiz

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
import kotlinx.coroutines.delay
import java.util.*
import javax.inject.Inject

@HiltViewModel
class ChooseDefinitionQuizViewModel @Inject constructor(
    private val wordManager: WordManager,
    private val quizSessionManager: QuizSessionManager,
    private val userStatsManager: UserStatsManager,
    private val wordProgressManager: WordProgressManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(ChooseDefinitionQuizUiState())
    val uiState: StateFlow<ChooseDefinitionQuizUiState> = _uiState.asStateFlow()

    private var quizWords: List<Word> = emptyList()
    private var allWords: List<Word> = emptyList()
    private var originalWords: List<Word> = emptyList()
    private var usedWords: MutableSet<Word> = mutableSetOf()
    private var wordsPlayed: MutableList<Word> = mutableListOf()
    private var currentSessionId: String? = null
    private var sessionStartTime: Date = Date()
    private var wordCount: Int = 10

    fun startQuiz(wordCount: Int = 10, hardWordsOnly: Boolean = false) {
        this.wordCount = wordCount
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Get words for the quiz based on hard words setting
                val allAvailableWords = wordManager.getAllWords()
                allWords = allAvailableWords // Initialize allWords for option generation
                val filteredWords = if (hardWordsOnly) {
                    allAvailableWords.filter { it.difficultyLevel == 2 }
                } else {
                    allAvailableWords
                }
                
                originalWords = filteredWords.shuffled()
                
                if (originalWords.isEmpty()) {
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
                
                // Check if we have enough words for the quiz
                if (originalWords.size < wordCount) {
                    _uiState.update { 
                        it.copy(
                            error = "Not enough words available. Need at least $wordCount words for the quiz.",
                            isLoading = false
                        )
                    }
                    return@launch
                }
                
                // Use all available words, don't limit at the beginning
                quizWords = originalWords
                
                // Create quiz session
                currentSessionId = UUID.randomUUID().toString()
                sessionStartTime = Date()
                
                _uiState.update { 
                    it.copy(
                        currentQuestionIndex = 0,
                        totalQuestions = wordCount,
                        score = 0,
                        progress = 0f,
                        currentStreak = 0,
                        bestStreak = 0,
                        questionsAnswered = 0,
                        isLoading = false
                    )
                }
                
                loadFirstWord()
                
            } catch (e: Exception) {
                Log.e("ChooseDefinitionQuizViewModel", "startQuiz error: ${e.message}", e)
                _uiState.update { 
                    it.copy(
                        error = "Failed to start quiz: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun selectOption(optionIndex: Int) {
        _uiState.update { it.copy(selectedOption = optionIndex) }
        // Automatically submit answer after selection (like iOS)
        submitAnswer()
    }

    fun submitAnswer() {
        val currentState = _uiState.value
        val selectedOption = currentState.selectedOption ?: return
        val currentWord = currentState.currentWord ?: return
        
        // Don't submit if already submitted
        if (currentState.isAnswerSubmitted) return
        
        val isCorrect = selectedOption == currentState.correctAnswerIndex
        
        // Add word to wordsPlayed list and mark as used
        wordsPlayed.add(currentWord)
        usedWords.add(currentWord)
        
        if (isCorrect) {
            // Correct answer
            _uiState.update { 
                it.copy(
                    isAnswerSubmitted = true,
                    isAnswerCorrect = true,
                    score = it.score + 100,
                    correctAnswers = it.correctAnswers + 1,
                    currentStreak = it.currentStreak + 1,
                    bestStreak = maxOf(it.bestStreak, it.currentStreak + 1),
                    questionsAnswered = it.questionsAnswered + 1,
                    progress = wordsPlayed.size.toFloat() / wordCount
                )
            }
            
            // Update word progress
            viewModelScope.launch {
                try {
                    wordProgressManager.incrementCorrectAnswers(currentWord.id)
                } catch (e: Exception) {
                    Log.e("ChooseDefinitionQuizViewModel", "Failed to update word progress: ${e.message}")
                }
            }
        } else {
            // Incorrect answer
            _uiState.update { 
                it.copy(
                    isAnswerSubmitted = true,
                    isAnswerCorrect = false,
                    score = maxOf(0, it.score - 25),
                    currentStreak = 0,
                    questionsAnswered = it.questionsAnswered + 1,
                    progress = wordsPlayed.size.toFloat() / wordCount
                )
            }
            
            // Update word progress and set difficulty level to 2 for incorrect answers
            viewModelScope.launch {
                try {
                    wordProgressManager.incrementIncorrectAnswers(currentWord.id)
                    // Directly set difficulty level to 2 (needs review) for incorrect answers
                    wordManager.updateDifficulty(currentWord, 2)
                } catch (e: Exception) {
                    Log.e("ChooseDefinitionQuizViewModel", "Failed to update word progress: ${e.message}")
                }
            }
        }
        
        // Check if quiz is complete immediately after answering
        val updatedState = _uiState.value
        if (updatedState.questionsAnswered >= wordCount) {
            scheduleQuizCompletion()
        } else {
            scheduleNextQuestion()
        }
    }

    fun skipWord() {
        val currentState = _uiState.value
        val currentWord = currentState.currentWord ?: return
        
        // Mark word as needing review and set difficulty level to 2
        viewModelScope.launch {
            try {
                wordProgressManager.markAsNeedsReview(currentWord.id)
                // Directly set difficulty level to 2 (needs review) for skipped words
                wordManager.updateDifficulty(currentWord, 2)
            } catch (e: Exception) {
                Log.e("ChooseDefinitionQuizViewModel", "Failed to mark word for review: ${e.message}")
            }
        }
        
        // Move current word to used set and add to wordsPlayed
        usedWords.add(currentWord)
        wordsPlayed.add(currentWord)
        
        _uiState.update { 
            it.copy(
                score = maxOf(0, it.score - 25),
                currentStreak = 0,
                questionsAnswered = it.questionsAnswered + 1,
                progress = wordsPlayed.size.toFloat() / wordCount
            )
        }
        
        // Check if quiz is complete
        if (currentState.questionsAnswered + 1 >= wordCount) {
            completeQuiz()
        } else {
            getNextQuestion()
        }
    }

    fun restartQuiz() {
        viewModelScope.launch {
            try {
                // Reset all game state
                originalWords = originalWords.shuffled()
                quizWords = originalWords
                usedWords.clear()
                wordsPlayed.clear()
                allWords = allWords // Keep allWords for option generation
                sessionStartTime = Date()
                
                _uiState.update { 
                    it.copy(
                        currentWord = null,
                        options = emptyList(),
                        selectedOption = null,
                        correctAnswerIndex = 0,
                        currentQuestionIndex = 0,
                        totalQuestions = wordCount,
                        score = 0,
                        progress = 0f,
                        isAnswerSubmitted = false,
                        isAnswerCorrect = false,
                        isQuizComplete = false,
                        currentStreak = 0,
                        bestStreak = 0,
                        questionsAnswered = 0,
                        correctAnswers = 0
                    )
                }
                
                loadFirstWord()
                
            } catch (e: Exception) {
                Log.e("ChooseDefinitionQuizViewModel", "restartQuiz error: ${e.message}", e)
                _uiState.update { 
                    it.copy(error = "Failed to restart quiz: ${e.message}")
                }
            }
        }
    }

    private fun loadFirstWord() {
        if (quizWords.isNotEmpty()) {
            val firstWord = quizWords[0]
            val options = generateOptions(firstWord)
            val correctAnswerIndex = options.indexOf(firstWord.definition)
            
            _uiState.update { 
                it.copy(
                    currentWord = firstWord,
                    currentQuestionIndex = 0,
                    options = options,
                    selectedOption = null,
                    correctAnswerIndex = correctAnswerIndex,
                    isAnswerSubmitted = false,
                    isAnswerCorrect = false,
                    progress = wordsPlayed.size.toFloat() / wordCount
                )
            }
        }
    }

    private fun getNextQuestion() {
        // Check if we've reached the word count limit
        val currentState = _uiState.value
        if (currentState.questionsAnswered >= wordCount) {
            completeQuiz()
            return
        }
        
        // Get available words (not used yet)
        val availableWords = originalWords.filter { !usedWords.contains(it) }
        
        if (availableWords.isNotEmpty()) {
            // Take a random available word as the correct one
            val correctWord = availableWords.shuffled().first()
            val options = generateOptions(correctWord)
            val correctAnswerIndex = options.indexOf(correctWord.definition)
            
            _uiState.update { 
                it.copy(
                    currentWord = correctWord,
                    options = options,
                    selectedOption = null,
                    correctAnswerIndex = correctAnswerIndex,
                    isAnswerSubmitted = false,
                    isAnswerCorrect = false,
                    progress = wordsPlayed.size.toFloat() / wordCount
                )
            }
        } else {
            // No more words available, but we haven't reached word count
            // This means we have fewer words than requested, so end the quiz
            completeQuiz()
        }
    }

    private fun generateOptions(correctWord: Word): List<String> {
        val correctDefinition = correctWord.definition
        val allDefinitions = allWords.map { it.definition }.distinct()
        
        // Remove the correct definition from the pool
        val availableDefinitions = allDefinitions.filter { it != correctDefinition }
        
        // Select 2 random incorrect definitions (to have 3 total options)
        val incorrectOptions = availableDefinitions.shuffled().take(2)
        
        // Combine correct and incorrect options, then shuffle
        val allOptions = (incorrectOptions + correctDefinition).shuffled()
        
        return allOptions
    }

    private fun scheduleNextQuestion() {
        viewModelScope.launch {
            // Wait 1.5 seconds before moving to next question
            delay(1500)
            moveToNextQuestion()
        }
    }
    
    private fun scheduleQuizCompletion() {
        viewModelScope.launch {
            // Wait 1.5 seconds before completing the quiz
            delay(1500)
            completeQuiz()
        }
    }
    
    private fun moveToNextQuestion() {
        val currentState = _uiState.value
        var newIndex = currentState.currentQuestionIndex + 1
        // Reset feedback
        _uiState.update { 
            it.copy(
                isAnswerSubmitted = false,
                isAnswerCorrect = false,
                selectedOption = null,
                currentQuestionIndex = newIndex
            )
        }
        
        // Get next question (quiz completion is already checked in submitAnswer)
        getNextQuestion()
    }

    private fun completeQuiz() {
        val currentState = _uiState.value
        
        viewModelScope.launch {
            try {
                // Save quiz session
                currentSessionId?.let { sessionId ->
                    val duration = (Date().time - sessionStartTime.time) / 1000.0 // Convert to seconds
                    val accuracy = if (wordsPlayed.isNotEmpty()) {
                        currentState.correctAnswers.toDouble() / wordsPlayed.size.toDouble()
                    } else 0.0
                    
                    quizSessionManager.saveQuizSession(
                        id = sessionId,
                        quizType = "definition",
                        totalQuestions = wordsPlayed.size, // Use words actually played
                        correctAnswers = currentState.correctAnswers,
                        timestamp = Date(),
                        duration = duration,
                        accuracy = accuracy,
                        score = currentState.score, // Add the score parameter
                        wordsPracticed = wordsPlayed.map { it.id }
                    )
                }
                
                // Update user stats
                userStatsManager.incrementQuizzesCompleted()
                userStatsManager.updateStreak()
                
                _uiState.update { 
                    it.copy(isQuizComplete = true)
                }
                
            } catch (e: Exception) {
                Log.e("ChooseDefinitionQuizViewModel", "completeQuiz error: ${e.message}", e)
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
                options = emptyList(),
                selectedOption = null,
                correctAnswerIndex = 0,
                currentQuestionIndex = 0,
                totalQuestions = 0,
                score = 0,
                progress = 0f,
                isAnswerSubmitted = false,
                isAnswerCorrect = false,
                isQuizComplete = false,
                currentStreak = 0,
                bestStreak = 0,
                questionsAnswered = 0,
                correctAnswers = 0
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }



    fun cleanupOnDisappear() {
        // If quiz is in progress but not complete, save partial session
        val currentState = _uiState.value
        if (!currentState.isQuizComplete && currentState.questionsAnswered > 0) {
            viewModelScope.launch {
                try {
                    // Save partial quiz session
                    currentSessionId?.let { sessionId ->
                        val duration = (Date().time - sessionStartTime.time) / 1000.0
                        val accuracy = if (currentState.totalQuestions > 0) {
                            currentState.correctAnswers.toDouble() / currentState.totalQuestions.toDouble()
                        } else 0.0
                        
                        quizSessionManager.saveQuizSession(
                            id = sessionId,
                            quizType = "definition",
                            totalQuestions = currentState.totalQuestions,
                            correctAnswers = currentState.correctAnswers,
                            timestamp = Date(),
                            duration = duration,
                            accuracy = accuracy,
                            score = currentState.score, // Add the score parameter
                            wordsPracticed = wordsPlayed.map { it.id }
                        )
                    }
                    
                    // Update user stats for partial completion
                    if (currentState.questionsAnswered > 0) {
                        userStatsManager.incrementQuizzesCompleted()
                    }
                    
                } catch (e: Exception) {
                    Log.e("ChooseDefinitionQuizViewModel", "cleanupOnDisappear error: ${e.message}", e)
                }
            }
        }
        
        // Reset state
        _uiState.update { 
            it.copy(
                currentWord = null,
                options = emptyList(),
                selectedOption = null,
                correctAnswerIndex = 0,
                currentQuestionIndex = 0,
                totalQuestions = 0,
                score = 0,
                progress = 0f,
                isAnswerSubmitted = false,
                isAnswerCorrect = false,
                isQuizComplete = false,
                currentStreak = 0,
                bestStreak = 0,
                questionsAnswered = 0,
                correctAnswers = 0
            )
        }
        
        // Clear session data
        currentSessionId = null
        quizWords = emptyList()
        allWords = emptyList()
        originalWords = emptyList()
        usedWords.clear()
    }
} 