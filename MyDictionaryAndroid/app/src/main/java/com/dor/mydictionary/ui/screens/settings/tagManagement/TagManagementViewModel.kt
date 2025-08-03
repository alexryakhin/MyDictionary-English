package com.dor.mydictionary.ui.screens.settings.tagManagement

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.Tag
import com.dor.mydictionary.core.TagColor
import com.dor.mydictionary.services.TagManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TagManagementViewModel @Inject constructor(
    private val tagManager: TagManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(TagManagementUiState())
    val uiState: StateFlow<TagManagementUiState> = _uiState.asStateFlow()

    fun loadTags() {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                val tags = tagManager.getAllTags()
                _uiState.update { it.copy(tags = tags, isLoading = false) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to load tags: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun addTag(name: String, color: TagColor) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                tagManager.addTag(name, color)
                loadTags() // Reload tags
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to add tag: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun editTag(tag: Tag) {
        // TODO: Implement edit functionality
        _uiState.update { it.copy(error = "Edit functionality not yet implemented") }
    }

    fun deleteTag(tag: Tag) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                tagManager.deleteTag(tag)
                loadTags() // Reload tags
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to delete tag: ${e.message}",
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

data class TagManagementUiState(
    val tags: List<Tag> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
) 