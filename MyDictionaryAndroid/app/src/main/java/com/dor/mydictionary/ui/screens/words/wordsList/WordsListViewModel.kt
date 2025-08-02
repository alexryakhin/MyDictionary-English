package com.dor.mydictionary.ui.screens.words.wordsList

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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

    private val _sortOrder = MutableStateFlow(SortOrder.ByTimestampNewestFirst)
    val sortOrder = _sortOrder.asStateFlow()

    private val _uiState = MutableStateFlow<List<Word>>(emptyList())
    val uiState = _uiState.asStateFlow()

    init {
        loadWords()
    }

    fun loadWords() {
        viewModelScope.launch {
            _uiState.value = wordManager.getAllWords()
        }
    }

    fun addWord(word: Word) {
        viewModelScope.launch {
            wordManager.updateWord(word)
            _uiState.value = wordManager.getAllWords()
        }
    }

    fun removeWord(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.deleteWord(it) }
            _uiState.value = wordManager.getAllWords()
        }
    }

    fun toggleFavorite(id: String) {
        viewModelScope.launch {
            val word = _uiState.value.find { it.id == id }
            word?.let { wordManager.toggleFavorite(it) }
            _uiState.value = wordManager.getAllWords()
        }
    }

    fun setSortOrder(order: SortOrder) {
        _sortOrder.value = order
        applySort()
    }

    private fun applySort() {
        _uiState.value = when (_sortOrder.value) {
            SortOrder.ByTimestampNewestFirst -> _uiState.value.sortedByDescending { it.timestamp }
            SortOrder.ByTimestampOldestFirst -> _uiState.value.sortedBy { it.timestamp }
            SortOrder.AlphabeticalAZ -> _uiState.value.sortedBy { it.wordItself }
            SortOrder.AlphabeticalZA -> _uiState.value.sortedByDescending { it.wordItself }
        }
    }
}