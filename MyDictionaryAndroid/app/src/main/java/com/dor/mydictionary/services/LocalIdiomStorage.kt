package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalIdiomStorage {
    @Query("SELECT * FROM idioms ORDER BY timestamp DESC")
    suspend fun getAll(): List<IdiomEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(idiom: IdiomEntity)

    @Delete
    suspend fun delete(idiom: IdiomEntity)

    @Update
    suspend fun update(idiom: IdiomEntity)

    @Query("SELECT * FROM idioms WHERE id = :id")
    suspend fun getById(id: String): IdiomEntity?

    @Query("SELECT * FROM idioms WHERE isFavorite = 1 ORDER BY timestamp DESC")
    suspend fun getFavorites(): List<IdiomEntity>
} 