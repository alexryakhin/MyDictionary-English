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
    private val wordnikService: WordnikService,
    private val wordManager: WordManager
) : ViewModel() {

    var wordInput by mutableStateOf("")
    var definitionInput by mutableStateOf("")
    var selectedPartOfSpeech by mutableStateOf<PartOfSpeech>(PartOfSpeech.Unknown)
    var transcription by mutableStateOf<String>("")
    var wordnikResults by mutableStateOf<List<WordnikDefinition>>(emptyList())
    var status by mutableStateOf(FetchingStatus.Blank)
    var selectedDefinitionIndex by mutableStateOf<Int?>(null)

    fun searchWordnik() {
        if (wordInput.trim().isEmpty()) return
        
        viewModelScope.launch {
            status = FetchingStatus.Loading
            try {
                val results = wordnikService.getDefinitions(wordInput.trim())
                wordnikResults = results
                
                // Auto-fill the first definition if available
                if (results.isNotEmpty()) {
                    val firstDefinition = results.first()
                    definitionInput = firstDefinition.definitionText
                    selectedPartOfSpeech = firstDefinition.partOfSpeech
                    transcription = firstDefinition.pronunciation ?: ""
                    selectedDefinitionIndex = 0
                }
                
                status = FetchingStatus.Ready
                Log.d("Wordnik results", results.toString())
            } catch (e: Exception) {
                wordnikResults = emptyList()
                status = FetchingStatus.Error
                Log.e("Wordnik error", "Error fetching definitions", e)
            }
        }
    }

    fun selectDefinition(index: Int, definition: WordnikDefinition) {
        selectedDefinitionIndex = index
        definitionInput = definition.definitionText
        selectedPartOfSpeech = definition.partOfSpeech
        transcription = definition.pronunciation ?: ""
    }

    fun playPronunciation() {
        // TODO: Implement TTS playback
        Log.d("TTS", "Playing pronunciation for: $wordInput")
    }

    fun saveWord(completion: (Word) -> Unit) {
        if (wordInput.trim().isEmpty() || definitionInput.trim().isEmpty()) return
        
        val word = Word(
            wordItself = wordInput.trim(),
            definition = definitionInput.trim(),
            partOfSpeech = selectedPartOfSpeech,
            phonetic = transcription.takeIf { it.isNotEmpty() },
            id = UUID.randomUUID().toString(),
            timestamp = Date(),
            examples = emptyList(), // TODO: Add examples from selected definition
            isFavorite = false,
            difficultyLevel = 0
        )
        
        viewModelScope.launch {
            try {
                wordManager.addWord(
                    wordItself = word.wordItself,
                    definition = word.definition,
                    partOfSpeech = word.partOfSpeech,
                    phonetic = word.phonetic,
                    examples = word.examples
                )
                completion(word)
                reset()
            } catch (e: Exception) {
                Log.e("Save word", "Error saving word", e)
            }
        }
    }

    private fun reset() {
        wordInput = ""
        definitionInput = ""
        selectedPartOfSpeech = PartOfSpeech.Unknown
        transcription = ""
        wordnikResults = emptyList()
        status = FetchingStatus.Blank
        selectedDefinitionIndex = null
    }
}
