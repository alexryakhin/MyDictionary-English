package com.dor.mydictionary.core

import java.util.Date

data class Idiom(
    val id: String,
    val idiomItself: String,
    val definition: String,
    val timestamp: Date,
    val isFavorite: Boolean,
    val examples: List<String>
) 