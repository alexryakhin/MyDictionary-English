package com.dor.mydictionary.ui.screens.settings

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordManager
import com.dor.mydictionary.services.NotificationService
import com.dor.mydictionary.services.CSVManager
import com.dor.mydictionary.services.FilePickerService
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
    private val wordManager: WordManager,
    private val notificationService: NotificationService,
    private val csvManager: CSVManager,
    private val filePickerService: FilePickerService
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
                userStatsManager.updateNotificationSettings(
                    dailyRemindersEnabled = enabled,
                    difficultWordsAlertsEnabled = _uiState.value.difficultWordsAlertsEnabled
                )
                
                _uiState.update { it.copy(dailyRemindersEnabled = enabled) }
                
                if (enabled) {
                    val granted = notificationService.requestPermission()
                    if (granted) {
                        notificationService.scheduleDailyReminder()
                    } else {
                        _uiState.update { it.copy(dailyRemindersEnabled = false) }
                        _uiState.update { it.copy(error = "Please enable notifications in system settings to receive daily reminders.") }
                        return@launch
                    }
                } else {
                    notificationService.cancelAllNotifications()
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update daily reminders: ${e.message}") }
            }
        }
    }

    fun setDifficultWordsAlertsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            try {
                userStatsManager.updateNotificationSettings(
                    dailyRemindersEnabled = _uiState.value.dailyRemindersEnabled,
                    difficultWordsAlertsEnabled = enabled
                )
                
                _uiState.update { it.copy(difficultWordsAlertsEnabled = enabled) }
                
                if (enabled) {
                    val granted = notificationService.requestPermission()
                    if (granted) {
                        notificationService.scheduleDifficultWordsAlert()
                    } else {
                        _uiState.update { it.copy(difficultWordsAlertsEnabled = false) }
                        _uiState.update { it.copy(error = "Please enable notifications in system settings to receive difficult words alerts.") }
                        return@launch
                    }
                } else {
                    notificationService.cancelAllNotifications()
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
                userStatsManager.updateTTSLanguage(language)
                _uiState.update { it.copy(selectedTTSLanguage = language) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to update TTS language: ${e.message}") }
            }
        }
    }

    fun importWords() {
        Log.d("SettingsViewModel", "importWords() called")
        viewModelScope.launch {
            try {
                Log.d("SettingsViewModel", "Starting import process")
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Signal that we need to show file picker
                Log.d("SettingsViewModel", "Setting shouldShowImportPicker = true")
                _uiState.update { it.copy(shouldShowImportPicker = true, isLoading = false) }
            } catch (e: Exception) {
                Log.e("SettingsViewModel", "Import failed: ${e.message}", e)
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
                
                val csvContent = csvManager.exportWordsToCSV(allWords)
                
                // Signal that we need to show file picker
                _uiState.update { 
                    it.copy(
                        shouldShowExportPicker = true, 
                        exportCsvContent = csvContent,
                        isLoading = false
                    ) 
                }
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

    fun handleImportFileSelected(uri: android.net.Uri?) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(shouldShowImportPicker = false, isLoading = true, error = null) }
                
                if (uri == null) {
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = "Please select a valid CSV file (.csv extension)"
                        ) 
                    }
                    return@launch
                }
                
                val fileContent = filePickerService.readFileContent(uri)
                if (fileContent == null) {
                    _uiState.update { 
                        it.copy(
                            error = "Failed to read file content. Please make sure the file is a valid CSV file.",
                            isLoading = false
                        ) 
                    }
                    return@launch
                }
                
                // Import words from CSV content
                Log.d("SettingsViewModel", "Starting CSV import with content length: ${fileContent.length}")
                try {
                    val importedWords = csvManager.importWordsFromCSV(fileContent)
                    Log.d("SettingsViewModel", "Import completed, imported $importedWords words")
                    
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = "Successfully imported $importedWords words"
                        ) 
                    }
                } catch (e: Exception) {
                    Log.e("SettingsViewModel", "Import failed: ${e.message}", e)
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = "Import failed: ${e.message}"
                        ) 
                    }
                }
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

    fun handleExportFileSelected(uri: android.net.Uri?) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(shouldShowExportPicker = false, isLoading = true, error = null) }
                
                if (uri == null) {
                    _uiState.update { it.copy(isLoading = false) }
                    return@launch
                }
                
                val csvContent = _uiState.value.exportCsvContent
                if (csvContent == null) {
                    _uiState.update { 
                        it.copy(
                            error = "No CSV content to export",
                            isLoading = false
                        ) 
                    }
                    return@launch
                }
                
                val success = filePickerService.writeFileContent(uri, csvContent)
                
                if (success) {
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = "Words exported successfully"
                        ) 
                    }
                } else {
                    _uiState.update { 
                        it.copy(
                            error = "Failed to write file",
                            isLoading = false
                        ) 
                    }
                }
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

    fun clearExportDialog() {
        _uiState.update { it.copy(shouldShowExportDialog = false, exportCsvContent = null) }
    }
} 