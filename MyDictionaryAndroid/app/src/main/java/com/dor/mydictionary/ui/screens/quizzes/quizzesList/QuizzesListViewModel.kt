package com.dor.mydictionary.ui.screens.quizzes.quizzesList

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.services.QuizSessionManager
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.min
import android.util.Log
import javax.inject.Inject

@HiltViewModel
class QuizzesListViewModel @Inject constructor(
    private val quizSessionManager: QuizSessionManager,
    private val userStatsManager: UserStatsManager,
    private val wordManager: WordManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(QuizzesListUiState())
    val uiState: StateFlow<QuizzesListUiState> = _uiState.asStateFlow()

    init {
        // Initialize with words count immediately
        viewModelScope.launch {
            wordManager.getAllWordsFlow().collect { allWords ->
                val hardWordsCount = allWords.filter { it.difficultyLevel == 2 }.size
                val totalWordsCount = allWords.size
                val currentState = _uiState.value
                val hardWordsOnly = currentState.practiceSettings.hardWordsOnly
                val availableWordsCount = if (hardWordsOnly) hardWordsCount else totalWordsCount
                
                Log.d("QuizzesListViewModel", "Total words: $totalWordsCount, Hard words: $hardWordsCount, Hard words only: $hardWordsOnly, Available words: $availableWordsCount")
                
                val maxWords = min(availableWordsCount, 50)
                val minWords = if (hardWordsOnly) 1 else 10
                val validatedWordsPerSession = currentState.practiceSettings.wordsPerSession.coerceIn(minWords, maxWords)
                
                _uiState.update { 
                    it.copy(
                        availableWordsCount = availableWordsCount,
                        hardWordsCount = hardWordsCount,
                        practiceSettings = it.practiceSettings.copy(
                            availableWordsCount = availableWordsCount,
                            wordsPerSession = validatedWordsPerSession
                        )
                    )
                }
            }
        }
    }

    fun toggleHardWordsOnly() {
        val currentHardWordsOnly = _uiState.value.practiceSettings.hardWordsOnly
        Log.d("QuizzesListViewModel", "Toggling hard words only from $currentHardWordsOnly to ${!currentHardWordsOnly}")
        _uiState.update {
            it.copy(
                practiceSettings = it.practiceSettings.copy(
                    hardWordsOnly = !it.practiceSettings.hardWordsOnly
                )
            )
        }
        
        // Update available words count when hard words setting changes
        viewModelScope.launch {
            val allWords = wordManager.getAllWords()
            val hardWordsCount = allWords.filter { it.difficultyLevel == 2 }.size
            val totalWordsCount = allWords.size
            val newHardWordsOnly = !currentHardWordsOnly
            val availableWordsCount = if (newHardWordsOnly) hardWordsCount else totalWordsCount
            
            Log.d("QuizzesListViewModel", "After toggle - Total words: $totalWordsCount, Hard words: $hardWordsCount, Hard words only: $newHardWordsOnly, Available words: $availableWordsCount")
            
            val maxWords = min(availableWordsCount, 50)
            val minWords = if (newHardWordsOnly) 1 else 10
            val validatedWordsPerSession = _uiState.value.practiceSettings.wordsPerSession.coerceIn(minWords, maxWords)
            
            _uiState.update { 
                it.copy(
                    availableWordsCount = availableWordsCount,
                    hardWordsCount = hardWordsCount,
                    practiceSettings = it.practiceSettings.copy(
                        availableWordsCount = availableWordsCount,
                        wordsPerSession = validatedWordsPerSession
                    )
                )
            }
        }
    }

    fun setWordsPerSession(count: Int) {
        val currentState = _uiState.value
        val maxWords = min(currentState.availableWordsCount, 50)
        val minWords = if (currentState.practiceSettings.hardWordsOnly) 1 else 10
        val validatedCount = count.coerceIn(minWords, maxWords)
        
        _uiState.update { 
            it.copy(
                practiceSettings = it.practiceSettings.copy(
                    wordsPerSession = validatedCount
                )
            )
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