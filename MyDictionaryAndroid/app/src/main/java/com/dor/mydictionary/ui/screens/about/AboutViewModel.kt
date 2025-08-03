package com.dor.mydictionary.ui.screens.about

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AboutViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

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

    fun openTwitter() {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://x.com/xander1100001"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Handle case where no browser is available
            println("Failed to open Twitter: ${e.message}")
        }
    }

    fun openInstagram() {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.instagram.com/ar_x101"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Handle case where no browser is available
            println("Failed to open Instagram: ${e.message}")
        }
    }

    fun openBuyMeACoffee() {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://buymeacoffee.com/xander1100001"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Handle case where no browser is available
            println("Failed to open Buy Me a Coffee: ${e.message}")
        }
    }

    fun openAppStoreRating() {
        try {
            // Open Google Play Store for rating
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=com.dor.mydictionary"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback to web version if Play Store app is not available
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=com.dor.mydictionary"))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            } catch (e2: Exception) {
                println("Failed to open app store rating: ${e2.message}")
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