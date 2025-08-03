package com.dor.mydictionary.ui.screens.about

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AboutViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(AboutUiState())
    val uiState: StateFlow<AboutUiState> = _uiState.asStateFlow()

    fun loadAppInfo() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // In a real app, you would load this from BuildConfig or PackageManager
                val appInfo = getAppInfo()
                
                _uiState.update {
                    it.copy(
                        appName = appInfo.first,
                        appVersion = appInfo.second,
                        buildNumber = appInfo.third,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to load app info: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    private fun getAppInfo(): Triple<String, String, String> {
        // This would typically come from BuildConfig or PackageManager
        // For now, we'll return hardcoded values
        return Triple(
            "My Dictionary",
            "1.0.0",
            "1"
        )
    }
} 