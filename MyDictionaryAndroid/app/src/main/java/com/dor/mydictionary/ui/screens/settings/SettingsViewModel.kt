package com.dor.mydictionary.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userStatsManager: UserStatsManager,
    private val wordManager: WordManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    fun loadSettings() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                val userStats = userStatsManager.getUserStats()
                val allWords = wordManager.getAllWords()
                val hasHardWords = allWords.any { it.difficultyLevel > 0 }
                
                _uiState.update {
                    it.copy(
                        dailyRemindersEnabled = userStats.dailyRemindersEnabled,
                        difficultWordsAlertsEnabled = userStats.difficultWordsAlertsEnabled,
                        practiceWordCount = userStats.wordsPerSession,
                        practiceHardWordsOnly = userStats.practiceHardWordsOnly,
                        hasHardWords = hasHardWords,
                        selectedTTSLanguage = userStats.selectedTTSLanguage,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to load settings: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun setDailyRemindersEnabled(enabled: Boolean) {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                val updatedStats = userStats.copy(dailyRemindersEnabled = enabled)
                userStatsManager.updateStats(updatedStats)
                
                _uiState.update { it.copy(dailyRemindersEnabled = enabled) }
                
                // TODO: Handle notification permissions and scheduling
                if (enabled) {
                    // Request notification permission and schedule notifications
                } else {
                    // Cancel notifications
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update daily reminders: ${e.message}") }
            }
        }
    }

    fun setDifficultWordsAlertsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                val updatedStats = userStats.copy(difficultWordsAlertsEnabled = enabled)
                userStatsManager.updateStats(updatedStats)
                
                _uiState.update { it.copy(difficultWordsAlertsEnabled = enabled) }
                
                // TODO: Handle notification permissions and scheduling
                if (enabled) {
                    // Request notification permission and schedule notifications
                } else {
                    // Cancel notifications
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update difficult words alerts: ${e.message}") }
            }
        }
    }

    fun setPracticeWordCount(count: Int) {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                val updatedStats = userStats.copy(wordsPerSession = count)
                userStatsManager.updateStats(updatedStats)
                
                _uiState.update { it.copy(practiceWordCount = count) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update practice word count: ${e.message}") }
            }
        }
    }

    fun setPracticeHardWordsOnly(enabled: Boolean) {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                val updatedStats = userStats.copy(practiceHardWordsOnly = enabled)
                userStatsManager.updateStats(updatedStats)
                
                _uiState.update { it.copy(practiceHardWordsOnly = enabled) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update practice hard words setting: ${e.message}") }
            }
        }
    }

    fun setSelectedTTSLanguage(language: String) {
        viewModelScope.launch {
            try {
                val userStats = userStatsManager.getUserStats()
                val updatedStats = userStats.copy(selectedTTSLanguage = language)
                userStatsManager.updateStats(updatedStats)
                
                _uiState.update { it.copy(selectedTTSLanguage = language) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update TTS language: ${e.message}") }
            }
        }
    }

    fun importWords() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // TODO: Implement CSV import functionality
                // This would involve:
                // 1. Opening file picker
                // 2. Reading CSV file
                // 3. Parsing and importing words
                // 4. Updating database
                
                _uiState.update { it.copy(isLoading = false) }
                _uiState.update { it.copy(error = "Import functionality not yet implemented") }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to import words: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun exportWords() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                val allWords = wordManager.getAllWords()
                if (allWords.isEmpty()) {
                    _uiState.update {
                        it.copy(
                            error = "No words to export",
                            isLoading = false
                        )
                    }
                    return@launch
                }
                
                // TODO: Implement CSV export functionality
                // This would involve:
                // 1. Converting words to CSV format
                // 2. Creating file
                // 3. Saving to device
                
                _uiState.update { it.copy(isLoading = false) }
                _uiState.update { it.copy(error = "Export functionality not yet implemented") }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to export words: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
} 