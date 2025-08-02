package com.dor.mydictionary.ui.screens.idioms.idiomDetails

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.Idiom
import com.dor.mydictionary.services.IdiomManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class IdiomDetailsViewModel @Inject constructor(
    private val idiomManager: IdiomManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(IdiomDetailsUiState())
    val uiState: StateFlow<IdiomDetailsUiState> = _uiState.asStateFlow()

    fun loadIdiom(idiomId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            try {
                val idiom = idiomManager.getById(idiomId)
                if (idiom != null) {
                    _uiState.update { 
                        it.copy(
                            idiom = idiom,
                            isLoading = false,
                            error = null
                        )
                    }
                } else {
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = "Idiom not found"
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = "Failed to load idiom: ${e.message}"
                    )
                }
            }
        }
    }

    fun toggleFavorite() {
        val currentIdiom = _uiState.value.idiom ?: return
        
        viewModelScope.launch {
            try {
                val updatedIdiom = currentIdiom.copy(isFavorite = !currentIdiom.isFavorite)
                idiomManager.updateIdiom(updatedIdiom)
                _uiState.update { it.copy(idiom = updatedIdiom) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to update favorite status: ${e.message}")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
} 