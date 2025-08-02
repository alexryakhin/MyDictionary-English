package com.dor.mydictionary.core

import java.util.Date

data class Tag(
    val id: String,
    val name: String,
    val color: TagColor,
    val timestamp: Date
) 