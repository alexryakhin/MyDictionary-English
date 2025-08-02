package com.dor.mydictionary.ui.screens.idioms.addIdiom

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
import java.util.Date
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddIdiomViewModel @Inject constructor(
    private val idiomManager: IdiomManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddIdiomUiState())
    val uiState: StateFlow<AddIdiomUiState> = _uiState.asStateFlow()

    fun setIdiomInput(input: String) {
        _uiState.update { it.copy(idiomInput = input) }
    }

    fun setMeaningInput(input: String) {
        _uiState.update { it.copy(meaningInput = input) }
    }

    fun setExamplesInput(input: String) {
        _uiState.update { it.copy(examplesInput = input) }
    }

    fun saveIdiom(onSuccess: (Idiom) -> Unit) {
        val currentState = _uiState.value
        
        if (currentState.idiomInput.isBlank()) {
            _uiState.update { it.copy(error = "Idiom cannot be empty") }
            return
        }
        
        if (currentState.meaningInput.isBlank()) {
            _uiState.update { it.copy(error = "Meaning cannot be empty") }
            return
        }

        // Prevent multiple saves while loading
        if (currentState.isLoading) {
            return
        }

        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                val examples = if (currentState.examplesInput.isNotBlank()) {
                    currentState.examplesInput.split("\n").filter { it.isNotBlank() }
                } else {
                    emptyList()
                }
                
                val idiom = Idiom(
                    id = UUID.randomUUID().toString(),
                    idiomItself = currentState.idiomInput.trim(),
                    definition = currentState.meaningInput.trim(),
                    timestamp = Date(),
                    isFavorite = false,
                    examples = examples
                )
                
                val savedIdiom = idiomManager.addIdiom(idiom)
                _uiState.update { it.copy(isLoading = false) }
                onSuccess(savedIdiom)
                
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = "Failed to save idiom: ${e.message}"
                    )
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
} 