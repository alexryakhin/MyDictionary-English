package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalQuizSessionStorage {
    @Query("SELECT * FROM quiz_sessions ORDER BY date DESC")
    suspend fun getAll(): List<QuizSessionEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(quizSession: QuizSessionEntity)

    @Delete
    suspend fun delete(quizSession: QuizSessionEntity)

    @Update
    suspend fun update(quizSession: QuizSessionEntity)

    @Query("SELECT * FROM quiz_sessions WHERE id = :id")
    suspend fun getById(id: String): QuizSessionEntity?

    @Query("SELECT * FROM quiz_sessions WHERE quizType = :quizType ORDER BY date DESC")
    suspend fun getByQuizType(quizType: String): List<QuizSessionEntity>

    @Query("SELECT * FROM quiz_sessions WHERE date >= :startDate ORDER BY date DESC")
    suspend fun getFromDate(startDate: java.util.Date): List<QuizSessionEntity>
} 