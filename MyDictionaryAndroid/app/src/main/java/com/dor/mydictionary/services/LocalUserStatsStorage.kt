package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalUserStatsStorage {
    @Query("SELECT * FROM user_stats LIMIT 1")
    suspend fun getCurrent(): UserStatsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(userStats: UserStatsEntity)

    @Update
    suspend fun update(userStats: UserStatsEntity)

    @Delete
    suspend fun delete(userStats: UserStatsEntity)
} 