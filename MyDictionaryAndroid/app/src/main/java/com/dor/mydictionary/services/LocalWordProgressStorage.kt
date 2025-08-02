package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalWordProgressStorage {
    @Query("SELECT * FROM word_progress ORDER BY lastPracticed DESC")
    suspend fun getAll(): List<WordProgressEntity>

    @Query("SELECT * FROM word_progress WHERE wordId = :wordId")
    suspend fun getByWordId(wordId: String): WordProgressEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(wordProgress: WordProgressEntity)

    @Update
    suspend fun update(wordProgress: WordProgressEntity)

    @Delete
    suspend fun delete(wordProgress: WordProgressEntity)

    @Query("SELECT * FROM word_progress WHERE masteryLevel = :masteryLevel")
    suspend fun getByMasteryLevel(masteryLevel: String): List<WordProgressEntity>
} 