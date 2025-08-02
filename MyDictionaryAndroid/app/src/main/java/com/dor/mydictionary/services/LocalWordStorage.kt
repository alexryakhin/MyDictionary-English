package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalWordStorage {
    @Query("SELECT * FROM words ORDER BY timestamp DESC")
    suspend fun getAll(): List<WordEntity>

    @Insert(onConflict = OnConflictStrategy.Companion.REPLACE)
    suspend fun insert(word: WordEntity)

    @Delete
    suspend fun delete(word: WordEntity)

    @Update
    suspend fun update(word: WordEntity)

    @Query("SELECT * FROM words WHERE id = :id")
    suspend fun getById(id: String): WordEntity?
}