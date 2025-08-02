package com.dor.mydictionary.ui.screens.idioms.idiomsList

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.Idiom
import com.dor.mydictionary.core.SortOrder
import com.dor.mydictionary.services.IdiomManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class IdiomsListViewModel @Inject constructor(
    private val idiomManager: IdiomManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(IdiomsListUiState())
    val uiState: StateFlow<IdiomsListUiState> = _uiState.asStateFlow()

    private val _sortOrder = MutableStateFlow(SortOrder.Latest)
    val sortOrder: StateFlow<SortOrder> = _sortOrder.asStateFlow()

    private val _searchText = MutableStateFlow("")
    val searchText: StateFlow<String> = _searchText.asStateFlow()

    private val _filterState = MutableStateFlow(IdiomFilterOption.All)
    val filterState: StateFlow<IdiomFilterOption> = _filterState.asStateFlow()

    init {
        loadIdioms()
    }

    fun loadIdioms() {
        viewModelScope.launch {
            try {
                val idioms = idiomManager.getAllIdioms()
                _uiState.update { it.copy(idioms = idioms, isLoading = false) }
                applyFilterAndSort()
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        error = "Failed to load idioms: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun setSortOrder(sortOrder: SortOrder) {
        _sortOrder.value = sortOrder
        applyFilterAndSort()
    }

    fun setSearchText(text: String) {
        _searchText.value = text
        applyFilterAndSort()
    }

    fun setFilter(filter: IdiomFilterOption) {
        _filterState.value = filter
        applyFilterAndSort()
    }

    fun toggleFavorite(idiomId: String) {
        viewModelScope.launch {
            try {
                val idiom = _uiState.value.idioms.find { it.id == idiomId }
                idiom?.let {
                    val updatedIdiom = it.copy(isFavorite = !it.isFavorite)
                    idiomManager.updateIdiom(updatedIdiom)
                    loadIdioms() // Reload to reflect changes
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to update favorite: ${e.message}")
                }
            }
        }
    }

    fun deleteIdiom(idiomId: String) {
        viewModelScope.launch {
            try {
                val idiom = _uiState.value.idioms.find { it.id == idiomId }
                idiom?.let {
                    idiomManager.deleteIdiom(it)
                    loadIdioms() // Reload to reflect changes
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to delete idiom: ${e.message}")
                }
            }
        }
    }

    fun addIdiom(idiom: Idiom) {
        viewModelScope.launch {
            try {
                idiomManager.addIdiom(idiom)
                loadIdioms() // Reload to reflect changes
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "Failed to add idiom: ${e.message}")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun applyFilterAndSort() {
        val idioms = _uiState.value.idioms
        val searchText = _searchText.value
        val filter = _filterState.value
        val sortOrder = _sortOrder.value

        // Apply search filter
        val searchFiltered = if (searchText.isEmpty()) {
            idioms
        } else {
            idioms.filter { idiom ->
                idiom.idiomItself.contains(searchText, ignoreCase = true)
            }
        }

        // Apply additional filters
        val filtered = when (filter) {
            IdiomFilterOption.All -> searchFiltered
            IdiomFilterOption.Favorites -> searchFiltered.filter { it.isFavorite }
        }

        // Apply sorting
        val sorted = when (sortOrder) {
            SortOrder.Latest -> filtered.sortedByDescending { it.timestamp }
            SortOrder.Earliest -> filtered.sortedBy { it.timestamp }
            SortOrder.Alphabetical -> filtered.sortedBy { it.idiomItself }
            SortOrder.ReverseAlphabetical -> filtered.sortedByDescending { it.idiomItself }
        }

        _uiState.update { 
            it.copy(
                filteredIdioms = sorted,
                idiomsCount = "${sorted.size} idiom${if (sorted.size != 1) "s" else ""}"
            )
        }
    }
}

data class IdiomsListUiState(
    val idioms: List<Idiom> = emptyList(),
    val filteredIdioms: List<Idiom> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val idiomsCount: String = "0 idioms"
)

enum class IdiomFilterOption(val displayName: String) {
    All("All"),
    Favorites("Favorites")
} 