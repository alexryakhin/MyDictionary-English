package com.dor.mydictionary.services.wordnik

import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.services.SensitiveConstant
import javax.inject.Inject

class WordnikService @Inject constructor(private val api: WordnikApi) {
    suspend fun getDefinitions(word: String): List<WordnikDefinition> {
        return api.getDefinitions(
            word = word,
            apiKey = SensitiveConstant.WORDNIK_API_KEY.value
        )
            .map { it.toDomain() }
            .filter { it.definitionText.isNotEmpty() && it.partOfSpeech != PartOfSpeech.Unknown }
    }
}