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

    suspend fun addIdiom(idiom: Idiom): Idiom {
        // Check if an idiom with the same content already exists
        val existingIdioms = storage.getAll()
        val duplicate = existingIdioms.find { 
            it.idiomItself.equals(idiom.idiomItself, ignoreCase = true) 
        }
        
        if (duplicate != null) {
            // Return the existing idiom instead of creating a duplicate
            return duplicate.toIdiom()
        }
        
        // Use the existing ID if provided, otherwise generate a new one
        val finalIdiom = if (idiom.id.isBlank()) {
            idiom.copy(id = UUID.randomUUID().toString())
        } else {
            idiom
        }
        storage.insert(IdiomEntity.fromIdiom(finalIdiom))
        return finalIdiom
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