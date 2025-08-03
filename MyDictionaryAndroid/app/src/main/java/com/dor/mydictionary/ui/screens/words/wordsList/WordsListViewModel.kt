package com.dor.mydictionary.ui.screens.words.wordsList

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.Difficulty
import com.dor.mydictionary.core.SortOrder
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.WordManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class WordsListViewModel @Inject constructor(
    private val wordManager: WordManager
) : ViewModel() {

    private val _sortOrder = MutableStateFlow(SortOrder.Latest)
    val sortOrder = _sortOrder.asStateFlow()

    private val _currentFilter = MutableStateFlow(FilterOption.ALL)
    val currentFilter = _currentFilter.asStateFlow()

    private val _searchText = MutableStateFlow("")
    val searchText = _searchText.asStateFlow()

    private val _uiState = MutableStateFlow<List<Word>>(emptyList())
    val uiState = _uiState.asStateFlow()

    init {
        // Use reactive Flow to automatically update when database changes
        viewModelScope.launch {
            combine(
                wordManager.getAllWordsFlow(),
                _sortOrder,
                _currentFilter,
                _searchText
            ) { words, sortOrder, filter, searchText ->
                applyFilterAndSort(words, sortOrder, filter, searchText)
            }.collect { filteredWords ->
                _uiState.value = filteredWords
            }
        }
    }

    fun addWord(word: Word) {
        viewModelScope.launch {
            wordManager.updateWord(word)
        }
    }

    fun removeWord(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.deleteWord(it) }
        }
    }

    fun toggleFavorite(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.toggleFavorite(it) }
        }
    }

    fun setSortOrder(order: SortOrder) {
        _sortOrder.value = order
    }

    fun setFilter(filter: FilterOption) {
        _currentFilter.value = filter
    }

    fun setSearchText(text: String) {
        _searchText.value = text
    }

    private fun applyFilterAndSort(
        words: List<Word>,
        sortOrder: SortOrder,
        filter: FilterOption,
        searchText: String
    ): List<Word> {
        // Apply search filter
        val searchFiltered = if (searchText.isEmpty()) {
            words
        } else {
            words.filter { word ->
                word.wordItself.contains(searchText, ignoreCase = true) ||
                word.definition.contains(searchText, ignoreCase = true)
            }
        }

        // Apply additional filters
        val filteredWords = when (filter) {
            FilterOption.ALL -> searchFiltered
            FilterOption.FAVORITES -> searchFiltered.filter { it.isFavorite }
            FilterOption.NEW -> searchFiltered.filter { it.difficultyLevel == 0 }
            FilterOption.IN_PROGRESS -> searchFiltered.filter { it.difficultyLevel == 1 }
            FilterOption.NEEDS_REVIEW -> searchFiltered.filter { it.difficultyLevel == 2 }
            FilterOption.MASTERED -> searchFiltered.filter { it.difficultyLevel == 3 }
        }

        return when (sortOrder) {
            SortOrder.Latest -> filteredWords.sortedByDescending { it.timestamp }
            SortOrder.Earliest -> filteredWords.sortedBy { it.timestamp }
            SortOrder.Alphabetical -> filteredWords.sortedBy { it.wordItself }
            SortOrder.ReverseAlphabetical -> filteredWords.sortedByDescending { it.wordItself }
        }
    }
}