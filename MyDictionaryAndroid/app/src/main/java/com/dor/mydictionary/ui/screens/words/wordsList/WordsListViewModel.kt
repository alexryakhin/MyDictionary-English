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

    private val _sortOrder = MutableStateFlow(SortOrder.ByTimestampNewestFirst)
    val sortOrder = _sortOrder.asStateFlow()

    private val _currentFilter = MutableStateFlow(FilterOption.ALL)
    val currentFilter = _currentFilter.asStateFlow()

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

    private fun applyFilterAndSort() {
        viewModelScope.launch {
            val allWords = wordManager.getAllWords()
            _uiState.value = applyFilterAndSort(allWords)
        }
    }

    private fun applyFilterAndSort(words: List<Word>): List<Word> {
        val filteredWords = when (_currentFilter.value) {
            FilterOption.ALL -> words
            FilterOption.FAVORITES -> words.filter { it.isFavorite }
            FilterOption.NEW -> words.filter { it.difficultyLevel == 0 }
            FilterOption.IN_PROGRESS -> words.filter { it.difficultyLevel == 1 }
            FilterOption.NEEDS_REVIEW -> words.filter { it.difficultyLevel == 2 }
            FilterOption.MASTERED -> words.filter { it.difficultyLevel == 3 }
        }

        return when (_sortOrder.value) {
            SortOrder.ByTimestampNewestFirst -> filteredWords.sortedByDescending { it.timestamp }
            SortOrder.ByTimestampOldestFirst -> filteredWords.sortedBy { it.timestamp }
            SortOrder.AlphabeticalAZ -> filteredWords.sortedBy { it.wordItself }
            SortOrder.AlphabeticalZA -> filteredWords.sortedByDescending { it.wordItself }
        }
    }

    fun addSampleData() {
        viewModelScope.launch {
            val sampleWords = listOf(
                Word(
                    wordItself = "Ephemeral",
                    definition = "Lasting for a very short time; transitory.",
                    partOfSpeech = com.dor.mydictionary.core.PartOfSpeech.Adjective,
                    phonetic = "ɪˈfem(ə)rəl",
                    id = "1",
                    timestamp = java.util.Date(),
                    examples = listOf("The ephemeral beauty of sunset", "Ephemeral fame"),
                    isFavorite = true,
                    difficultyLevel = 2
                ),
                Word(
                    wordItself = "Serendipity",
                    definition = "The occurrence and development of events by chance in a happy or beneficial way.",
                    partOfSpeech = com.dor.mydictionary.core.PartOfSpeech.Noun,
                    phonetic = "ˌserənˈdipədē",
                    id = "2",
                    timestamp = java.util.Date(),
                    examples = listOf("Finding that book was pure serendipity"),
                    isFavorite = false,
                    difficultyLevel = 1
                ),
                Word(
                    wordItself = "Ubiquitous",
                    definition = "Present, appearing, or found everywhere.",
                    partOfSpeech = com.dor.mydictionary.core.PartOfSpeech.Adjective,
                    phonetic = "yo͞oˈbikwədəs",
                    id = "3",
                    timestamp = java.util.Date(),
                    examples = listOf("Ubiquitous computing devices"),
                    isFavorite = true,
                    difficultyLevel = 3
                )
            )

            sampleWords.forEach { word ->
                wordManager.updateWord(word)
            }

            loadWords()
        }
    }
}