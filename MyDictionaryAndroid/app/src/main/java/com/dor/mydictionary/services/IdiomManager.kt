package com.dor.mydictionary.services

import com.dor.mydictionary.core.Idiom
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class IdiomManager @Inject constructor(
    private val storage: LocalIdiomStorage
) {
    suspend fun getAllIdioms(): List<Idiom> {
        return storage.getAll().map { it.toIdiom() }
    }

    suspend fun getFavoriteIdioms(): List<Idiom> {
        return storage.getFavorites().map { it.toIdiom() }
    }

    suspend fun getById(id: String): Idiom? {
        return storage.getById(id)?.toIdiom()
    }

    suspend fun addIdiom(
        idiomItself: String,
        definition: String,
        examples: List<String> = emptyList()
    ): Idiom {
        val idiom = Idiom(
            id = UUID.randomUUID().toString(),
            idiomItself = idiomItself,
            definition = definition,
            timestamp = Date(),
            isFavorite = false,
            examples = examples
        )
        
        storage.insert(IdiomEntity.fromIdiom(idiom))
        return idiom
    }

    suspend fun updateIdiom(idiom: Idiom) {
        storage.update(IdiomEntity.fromIdiom(idiom))
    }

    suspend fun deleteIdiom(idiom: Idiom) {
        storage.delete(IdiomEntity.fromIdiom(idiom))
    }

    suspend fun toggleFavorite(idiom: Idiom): Idiom {
        val updatedIdiom = idiom.copy(isFavorite = !idiom.isFavorite)
        storage.update(IdiomEntity.fromIdiom(updatedIdiom))
        return updatedIdiom
    }
} 