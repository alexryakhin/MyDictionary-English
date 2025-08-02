package com.dor.mydictionary.services.wordnik

import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface WordnikApi {
    @GET("word.json/{word}/definitions")
    suspend fun getDefinitions(
        @Path("word") word: String,
        @Query("limit") limit: Int = 10,
        @Query("includeRelated") includeRelated: Boolean = false,
        @Query("sourceDictionaries") sourceDictionaries: String = "all",
        @Query("useCanonical") useCanonical: Boolean = true,
        @Query("includeTags") includeTags: Boolean = false,
        @Query("api_key") apiKey: String
    ): List<WordnikDefinitionDto>
}