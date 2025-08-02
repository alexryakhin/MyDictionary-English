package com.dor.mydictionary.ui.screens.quizzes.quizzesList

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.services.QuizSessionManager
import com.dor.mydictionary.services.UserStatsManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class QuizzesListViewModel @Inject constructor(
    private val quizSessionManager: QuizSessionManager,
    private val userStatsManager: UserStatsManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(QuizzesListUiState())
    val uiState: StateFlow<QuizzesListUiState> = _uiState.asStateFlow()

    init {
        loadRecentQuizResults()
        loadPracticeSettings()
    }

    fun togglePracticeSettings() {
        _uiState.update { it.copy(showPracticeSettings = !it.showPracticeSettings) }
    }

    fun toggleHardWordsOnly() {
        _uiState.update { 
            it.copy(
                practiceSettings = it.practiceSettings.copy(
                    hardWordsOnly = !it.practiceSettings.hardWordsOnly
                )
            )
        }
        savePracticeSettings()
    }

    fun setWordsPerSession(count: Int) {
        _uiState.update { 
            it.copy(
                practiceSettings = it.practiceSettings.copy(
                    wordsPerSession = count
                )
            )
        }
        savePracticeSettings()
    }

    private fun loadRecentQuizResults() {
        viewModelScope.launch {
            try {
                val recentSessions = quizSessionManager.getRecentSessions(limit = 10)
                val results = recentSessions.map { session ->
                    QuizResult(
                        quizType = session.quizType,
                        score = session.correctAnswers,
                        totalWords = session.totalWords,
                        date = formatDate(session.date)
                    )
                }
                _uiState.update { it.copy(recentQuizResults = results) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to load recent results: ${e.message}")
                }
            }
        }
    }

    private fun loadPracticeSettings() {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                _uiState.update { 
                    it.copy(
                        practiceSettings = PracticeSettings(
                            hardWordsOnly = userStats.practiceHardWordsOnly,
                            wordsPerSession = userStats.wordsPerSession
                        )
                    )
                }
            } catch (e: Exception) {
                // Use default settings if loading fails
                _uiState.update { 
                    it.copy(
                        practiceSettings = PracticeSettings(
                            hardWordsOnly = false,
                            wordsPerSession = 10
                        )
                    )
                }
            }
        }
    }

    private fun savePracticeSettings() {
        viewModelScope.launch {
            try {
                val currentSettings = _uiState.value.practiceSettings
                userStatsManager.updatePracticeSettings(
                    hardWordsOnly = currentSettings.hardWordsOnly,
                    wordsPerSession = currentSettings.wordsPerSession
                )
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to save practice settings: ${e.message}")
                }
            }
        }
    }

    private fun formatDate(date: Date): String {
        val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
        return formatter.format(date)
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
} 