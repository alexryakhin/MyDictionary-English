package com.dor.mydictionary.services

import android.content.Context
import android.net.Uri
import android.util.Log
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.services.WordManager
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CSVManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val wordManager: WordManager
) {
    
    suspend fun importWordsFromCSV(uri: Uri, currentWordIds: List<String>): List<Word> = withContext(Dispatchers.IO) {
        val words = mutableListOf<Word>()
        
        try {
            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                BufferedReader(InputStreamReader(inputStream)).use { reader ->
                    // Skip header line
                    reader.readLine()
                    
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        line?.let { csvLine ->
                            val word = parseCSVLine(csvLine, currentWordIds)
                            word?.let { words.add(it) }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            throw Exception("Failed to import CSV: ${e.message}")
        }
        
        words
    }
    
    suspend fun importWordsFromCSV(csvContent: String): Int = withContext(Dispatchers.IO) {
        val words = mutableListOf<Word>()
        
        try {
            val lines = csvContent.lines()
            if (lines.isEmpty()) return@withContext 0
            
            Log.d("CSVManager", "Found ${lines.size} lines")
            
            // Get current word IDs to avoid duplicates
            val currentWordIds = wordManager.getAllWords().map { it.id }.toSet()
            Log.d("CSVManager", "Current word count: ${currentWordIds.size}")
            
            // Skip header line
            lines.drop(1).forEachIndexed { index, line ->
                if (line.isNotEmpty()) {
                    Log.d("CSVManager", "Processing line ${index + 1}: ${line.take(50)}...")
                    val word = parseCSVLine(line, currentWordIds.toList())
                    word?.let { 
                        words.add(it)
                        Log.d("CSVManager", "Successfully parsed word: ${it.wordItself}")
                    } ?: Log.d("CSVManager", "Failed to parse line ${index + 1}")
                }
            }
            
            Log.d("CSVManager", "Parsed ${words.size} words")
            
            // Save words to database
            words.forEach { word ->
                wordManager.addWord(word)
                Log.d("CSVManager", "Saved word: ${word.wordItself}")
            }
            
            Log.d("CSVManager", "Successfully imported ${words.size} words")
            words.size
        } catch (e: Exception) {
            Log.e("CSVManager", "CSV Import Error: ${e.message}", e)
            throw Exception("Failed to import CSV content: ${e.message}")
        }
    }
    
    suspend fun exportWordsToCSV(words: List<Word>): String = withContext(Dispatchers.IO) {
        val csvBuilder = StringBuilder()
        
        // Add header - match iOS format exactly
        csvBuilder.append("word,definition,partOfSpeech,phonetic,is_favorite,timestamp,id,examples\n")
        
        // Add word data
        words.forEach { word ->
            val examples = word.examples.joinToString(";")
            val timestamp = word.timestamp.toISO8601String()
            
            val csvRow = listOf(
                word.wordItself,
                word.definition,
                word.partOfSpeech.rawValue,
                word.phonetic ?: "",
                if (word.isFavorite) "true" else "false",
                timestamp,
                word.id,
                examples
            ).map { "\"$it\"" }.joinToString(",")
            
            csvBuilder.append("$csvRow\n")
        }
        
        csvBuilder.toString()
    }
    
    private fun Date.toISO8601String(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        return formatter.format(this)
    }
    
    private fun parseISO8601Date(dateString: String): Date {
        return try {
            val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            formatter.parse(dateString) ?: Date()
        } catch (e: Exception) {
            Date() // Return current date if parsing fails
        }
    }
    
    private fun parseCSVLine(line: String, currentWordIds: List<String>): Word? {
        try {
            val parts = parseCSVLineParts(line)
            Log.d("CSVManager", "Line has ${parts.size} parts")
            
            if (parts.size < 8) {
                Log.d("CSVManager", "Not enough parts (expected 8, got ${parts.size})")
                return null
            }
            
            val wordText = parts[0].removeSurrounding("\"")
            val definition = parts[1].removeSurrounding("\"")
            val partOfSpeech = parts[2].removeSurrounding("\"")
            val phonetic = parts[3].removeSurrounding("\"")
            val isFavorite = parts[4].removeSurrounding("\"").lowercase() == "true"
            val timestamp = parseISO8601Date(parts[5].removeSurrounding("\""))
            val id = parts[6].removeSurrounding("\"")
            val examples = parts[7].removeSurrounding("\"").split(";").filter { it.isNotEmpty() }
            
            Log.d("CSVManager", "Parsed word='$wordText', id='$id', partOfSpeech='$partOfSpeech'")
            
            // Skip if word already exists
            if (currentWordIds.contains(id)) {
                Log.d("CSVManager", "Word with ID $id already exists, skipping")
                return null
            }
            
            return Word(
                id = id,
                wordItself = wordText,
                definition = definition,
                partOfSpeech = PartOfSpeech.fromRawValue(partOfSpeech),
                phonetic = phonetic.takeIf { it.isNotEmpty() },
                timestamp = timestamp,
                examples = examples,
                isFavorite = isFavorite,
                difficultyLevel = 0 // Default to new difficulty level
            )
        } catch (e: Exception) {
            Log.e("CSVManager", "CSV Parse Error: ${e.message}", e)
            return null
        }
    }
    
    private fun parseCSVLineParts(line: String): List<String> {
        val parts = mutableListOf<String>()
        val currentPart = StringBuilder()
        var inQuotes = false
        var i = 0
        
        while (i < line.length) {
            val char = line[i]
            
            when {
                char == '"' && !inQuotes -> inQuotes = true
                char == '"' && inQuotes -> {
                    if (i + 1 < line.length && line[i + 1] == '"') {
                        // Escaped quote
                        currentPart.append('"')
                        i++ // Skip next quote
                    } else {
                        inQuotes = false
                    }
                }
                char == ',' && !inQuotes -> {
                    parts.add(currentPart.toString())
                    currentPart.clear()
                }
                else -> currentPart.append(char)
            }
            i++
        }
        
        parts.add(currentPart.toString())
        return parts
    }
} 