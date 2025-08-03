package com.dor.mydictionary.services

import com.dor.mydictionary.core.Word
import com.dor.mydictionary.core.PartOfSpeech
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class WordManager @Inject constructor(
    private val localStorage: LocalWordStorage,
    private val userStatsManager: UserStatsManager
) {
    suspend fun getAllWords(): List<Word> {
        return localStorage.getAll().map { it.toWord() }
    }

    fun getAllWordsFlow(): Flow<List<Word>> {
        return localStorage.getAllFlow().map { entities ->
            entities.map { it.toWord() }
        }
    }

    suspend fun getFavoriteWords(): List<Word> {
        return localStorage.getAll().filter { it.isFavorite }.map { it.toWord() }
    }

    suspend fun getById(id: String): Word? {
        return localStorage.getById(id)?.toWord()
    }

    suspend fun getWordById(id: String): Word? {
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
        
        // Update vocabulary size in user stats
        updateVocabularySize()
        
        return word
    }

    suspend fun addWord(word: Word) {
        localStorage.insert(WordEntity.fromWord(word))
        updateVocabularySize()
    }

    suspend fun updateWord(word: Word) {
        localStorage.update(WordEntity.fromWord(word))
    }

    suspend fun deleteWord(word: Word) {
        localStorage.delete(WordEntity.fromWord(word))
        updateVocabularySize()
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

    suspend fun getHardWords(): List<Word> {
        return localStorage.getAll().filter { it.difficultyLevel > 0 }.map { it.toWord() }
    }

    suspend fun getWordsByDifficultyLevel(difficultyLevel: Int): List<Word> {
        return localStorage.getAll().filter { it.difficultyLevel == difficultyLevel }.map { it.toWord() }
    }

    suspend fun getNewWords(): List<Word> {
        return getWordsByDifficultyLevel(0)
    }

    suspend fun getInProgressWords(): List<Word> {
        return getWordsByDifficultyLevel(1)
    }

    suspend fun getNeedsReviewWords(): List<Word> {
        return getWordsByDifficultyLevel(2)
    }

    suspend fun getMasteredWords(): List<Word> {
        return getWordsByDifficultyLevel(3)
    }

    suspend fun getProgressSummary(): ProgressSummary {
        val allWords = getAllWords()
        
        val newWords = allWords.count { it.difficultyLevel == 0 }
        val inProgressWords = allWords.count { it.difficultyLevel == 1 }
        val needsReviewWords = allWords.count { it.difficultyLevel == 2 }
        val masteredWords = allWords.count { it.difficultyLevel == 3 }
        
        return ProgressSummary(
            newWords = newWords,
            inProgressWords = inProgressWords,
            needsReviewWords = needsReviewWords,
            masteredWords = masteredWords,
            totalWords = allWords.size
        )
    }

    private suspend fun updateVocabularySize() {
        try {
            val allWords = getAllWords()
            userStatsManager.updateVocabularySize(allWords.size)
        } catch (e: Exception) {
            // Log error but don't crash
            android.util.Log.e("WordManager", "Failed to update vocabulary size: ${e.message}")
        }
    }
}

data class ProgressSummary(
    val newWords: Int,
    val inProgressWords: Int,
    val needsReviewWords: Int,
    val masteredWords: Int,
    val totalWords: Int
)