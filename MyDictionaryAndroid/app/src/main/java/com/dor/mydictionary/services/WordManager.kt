package com.dor.mydictionary.services

import com.dor.mydictionary.core.Word
import com.dor.mydictionary.core.PartOfSpeech
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class WordManager @Inject constructor(
    private val localStorage: LocalWordStorage
) {
    suspend fun getAllWords(): List<Word> {
        return localStorage.getAll().map { it.toWord() }
    }

    suspend fun getFavoriteWords(): List<Word> {
        return localStorage.getAll().filter { it.isFavorite }.map { it.toWord() }
    }

    suspend fun getById(id: String): Word? {
        return localStorage.getById(id)?.toWord()
    }

    suspend fun addWord(
        wordItself: String,
        definition: String,
        partOfSpeech: PartOfSpeech,
        phonetic: String? = null,
        examples: List<String> = emptyList()
    ): Word {
        val word = Word(
            wordItself = wordItself,
            definition = definition,
            partOfSpeech = partOfSpeech,
            phonetic = phonetic,
            id = UUID.randomUUID().toString(),
            timestamp = Date(),
            examples = examples,
            isFavorite = false,
            difficultyLevel = 0
        )
        
        localStorage.insert(WordEntity.fromWord(word))
        return word
    }

    suspend fun updateWord(word: Word) {
        localStorage.update(WordEntity.fromWord(word))
    }

    suspend fun deleteWord(word: Word) {
        localStorage.delete(WordEntity.fromWord(word))
    }

    suspend fun toggleFavorite(word: Word): Word {
        val updatedWord = word.copy(isFavorite = !word.isFavorite)
        localStorage.update(WordEntity.fromWord(updatedWord))
        return updatedWord
    }

    suspend fun updateDifficulty(word: Word, difficultyLevel: Int): Word {
        val updatedWord = word.copy(difficultyLevel = difficultyLevel)
        localStorage.update(WordEntity.fromWord(updatedWord))
        return updatedWord
    }
}