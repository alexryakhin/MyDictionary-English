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
        loadWords()
    }

    fun loadWords() {
        viewModelScope.launch {
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    fun addWord(word: Word) {
        viewModelScope.launch {
            wordManager.updateWord(word)
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    fun removeWord(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.deleteWord(it) }
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    fun toggleFavorite(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.toggleFavorite(it) }
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    fun setSortOrder(order: SortOrder) {
        _sortOrder.value = order
        applyFilterAndSort()
    }

    fun setFilter(filter: FilterOption) {
        _currentFilter.value = filter
        applyFilterAndSort()
    }

    fun setSearchText(text: String) {
        _searchText.value = text
        applyFilterAndSort()
    }

    private fun applyFilterAndSort() {
        viewModelScope.launch {
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    private fun applyFilterAndSort(words: List<Word>): List<Word> {
        // Apply search filter
        val searchFiltered = if (_searchText.value.isEmpty()) {
            words
        } else {
            words.filter { word ->
                word.wordItself.contains(_searchText.value, ignoreCase = true) ||
                word.definition.contains(_searchText.value, ignoreCase = true)
            }
        }

        // Apply additional filters
        val filteredWords = when (_currentFilter.value) {
            FilterOption.ALL -> searchFiltered
            FilterOption.FAVORITES -> searchFiltered.filter { it.isFavorite }
            FilterOption.NEW -> searchFiltered.filter { it.difficultyLevel == 0 }
            FilterOption.IN_PROGRESS -> searchFiltered.filter { it.difficultyLevel == 1 }
            FilterOption.NEEDS_REVIEW -> searchFiltered.filter { it.difficultyLevel == 2 }
            FilterOption.MASTERED -> searchFiltered.filter { it.difficultyLevel == 3 }
        }

        return when (_sortOrder.value) {
            SortOrder.Latest -> filteredWords.sortedByDescending { it.timestamp }
            SortOrder.Earliest -> filteredWords.sortedBy { it.timestamp }
            SortOrder.Alphabetical -> filteredWords.sortedBy { it.wordItself }
            SortOrder.ReverseAlphabetical -> filteredWords.sortedByDescending { it.wordItself }
        }
    }
}