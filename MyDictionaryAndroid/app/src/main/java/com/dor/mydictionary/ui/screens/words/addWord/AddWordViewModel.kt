package com.dor.mydictionary.ui.screens.words.addWord

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.FetchingStatus
import com.dor.mydictionary.services.WordManager
import com.dor.mydictionary.services.wordnik.WordnikDefinition
import com.dor.mydictionary.services.wordnik.WordnikService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import java.util.Date
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddWordViewModel @Inject constructor(
    private val wordnikService: WordnikService
) : ViewModel() {

    var wordInput by mutableStateOf("")
    var definitionInput by mutableStateOf("")
    var selectedPartOfSpeech by mutableStateOf<PartOfSpeech>(PartOfSpeech.Unknown)

    var transcription by mutableStateOf<String>("")
    var wordnikResults by mutableStateOf<List<WordnikDefinition>>(emptyList())
    var status by mutableStateOf(FetchingStatus.Blank)

    fun searchWordnik() {
        viewModelScope.launch {
            status = FetchingStatus.Loading
            try {
                val results = wordnikService.getDefinitions(wordInput)
                wordnikResults = results
                Log.d("Wordnik results", results.toString())
            } catch (e: Exception) {
                wordnikResults = emptyList()
                status = FetchingStatus.Error
            } finally {
                status = FetchingStatus.Ready
            }
        }
    }

    fun saveWord(completion: (Word) -> Unit) {
        val word = Word(
            wordItself = wordInput.trim(),
            definition = definitionInput.trim(),
            partOfSpeech = selectedPartOfSpeech,
            phonetic = transcription,
            id = UUID.randomUUID().toString(),
            timestamp = Date(),
            isFavorite = false,
            examples = emptyList(), // You can pull this from WordnikResult later
            difficultyLevel = 0
        )
        completion(word)
        reset()
    }

    private fun reset() {
        wordInput = ""
        definitionInput = ""
        selectedPartOfSpeech = PartOfSpeech.Unknown
        transcription = ""
        wordnikResults = emptyList()
        status = FetchingStatus.Blank
    }
}