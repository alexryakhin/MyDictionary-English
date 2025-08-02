package com.dor.mydictionary.ui.screens.progress

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.services.QuizSessionManager
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordManager
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
class ProgressAnalyticsViewModel @Inject constructor(
    private val userStatsManager: UserStatsManager,
    private val wordManager: WordManager,
    private val quizSessionManager: QuizSessionManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProgressAnalyticsUiState())
    val uiState: StateFlow<ProgressAnalyticsUiState> = _uiState.asStateFlow()

    fun loadProgressData() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Load user statistics
                loadUserStats()
                
                // Load vocabulary growth data
                loadVocabularyGrowthData()
                
                // Load recent quiz results
                loadRecentQuizResults()
                
                _uiState.update { it.copy(isLoading = false) }
                
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        error = "Failed to load progress data: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun refreshData() {
        loadProgressData()
    }

    fun setSelectedPeriod(period: ChartPeriod) {
        _uiState.update { it.copy(selectedPeriod = period) }
        viewModelScope.launch {
            loadVocabularyGrowthData()
        }
    }

    private suspend fun loadUserStats() {
        try {
            val userStats = userStatsManager.getUserStats()
            val allWords = wordManager.getAllWords()
            
            // TODO: Get actual progress data from WordProgressManager
            // For now, use mock data based on total words
            val totalWords = allWords.size
            val inProgress = (totalWords * 0.3).toInt()
            val mastered = (totalWords * 0.5).toInt()
            val needsReview = (totalWords * 0.2).toInt()
            
            _uiState.update { 
                it.copy(
                    inProgress = inProgress,
                    mastered = mastered,
                    needsReview = needsReview,
                    averageAccuracy = userStats.averageAccuracy,
                    totalSessions = userStats.totalSessions,
                    totalPracticeTime = userStats.totalPracticeTime
                )
            }
        } catch (e: Exception) {
            _uiState.update { 
                it.copy(error = "Failed to load user stats: ${e.message}")
            }
        }
    }

    private suspend fun loadVocabularyGrowthData() {
        try {
            val currentPeriod = _uiState.value.selectedPeriod
            val chartData = generateVocabularyGrowthData(currentPeriod)
            
            _uiState.update { it.copy(vocabularyGrowthData = chartData) }
        } catch (e: Exception) {
            _uiState.update { 
                it.copy(error = "Failed to load vocabulary growth data: ${e.message}")
            }
        }
    }

    private suspend fun loadRecentQuizResults() {
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
                it.copy(error = "Failed to load recent quiz results: ${e.message}")
            }
        }
    }

    private fun generateVocabularyGrowthData(period: ChartPeriod): List<ChartDataPoint> {
        // TODO: Implement actual vocabulary growth calculation
        // For now, return mock data
        return when (period) {
            ChartPeriod.Week -> {
                listOf(
                    ChartDataPoint("Mon", 5),
                    ChartDataPoint("Tue", 8),
                    ChartDataPoint("Wed", 12),
                    ChartDataPoint("Thu", 15),
                    ChartDataPoint("Fri", 18),
                    ChartDataPoint("Sat", 20),
                    ChartDataPoint("Sun", 22)
                )
            }
            ChartPeriod.Month -> {
                listOf(
                    ChartDataPoint("Week 1", 10),
                    ChartDataPoint("Week 2", 25),
                    ChartDataPoint("Week 3", 40),
                    ChartDataPoint("Week 4", 55)
                )
            }
            ChartPeriod.Year -> {
                listOf(
                    ChartDataPoint("Jan", 50),
                    ChartDataPoint("Feb", 75),
                    ChartDataPoint("Mar", 100),
                    ChartDataPoint("Apr", 125),
                    ChartDataPoint("May", 150),
                    ChartDataPoint("Jun", 175),
                    ChartDataPoint("Jul", 200),
                    ChartDataPoint("Aug", 225),
                    ChartDataPoint("Sep", 250),
                    ChartDataPoint("Oct", 275),
                    ChartDataPoint("Nov", 300),
                    ChartDataPoint("Dec", 325)
                )
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