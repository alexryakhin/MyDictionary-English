package com.dor.mydictionary.services

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.FragmentActivity
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class FilePickerService(private val context: Context) {
    
    fun createImportFilePicker(activity: FragmentActivity, onFileSelected: (Uri?) -> Unit) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "text/csv"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        
        val launcher = activity.registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            if (result.resultCode == FragmentActivity.RESULT_OK) {
                val uri = result.data?.data
                onFileSelected(uri)
            } else {
                onFileSelected(null)
            }
        }
        
        launcher.launch(intent)
    }
    
    fun createExportFilePicker(activity: FragmentActivity, fileName: String, onFileSelected: (Uri?) -> Unit) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            type = "text/csv"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        
        val launcher = activity.registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            if (result.resultCode == FragmentActivity.RESULT_OK) {
                val uri = result.data?.data
                onFileSelected(uri)
            } else {
                onFileSelected(null)
            }
        }
        
        launcher.launch(intent)
    }
    
    fun readFileContent(uri: Uri): String? {
        return try {
            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                inputStream.bufferedReader().use { reader ->
                    reader.readText()
                }
            }
        } catch (e: IOException) {
            null
        }
    }
    
    fun writeFileContent(uri: Uri, content: String): Boolean {
        return try {
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(content.toByteArray())
            }
            true
        } catch (e: IOException) {
            false
        }
    }
} 