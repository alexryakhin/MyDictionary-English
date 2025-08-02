package com.dor.mydictionary.ui.screens.idioms.addIdiom

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Idiom
import com.dor.mydictionary.ui.theme.Typography
import java.util.Date
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddIdiomSheet(
    onDismiss: () -> Unit,
    onSave: (Idiom) -> Unit,
    viewModel: AddIdiomViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = AddIdiomUiState())

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Add new idiom", style = Typography.headlineLarge)
            TextButton(
                onClick = {
                    viewModel.saveIdiom { idiom ->
                        onSave(idiom)
                    }
                },
                enabled = uiState.idiomInput.isNotEmpty() && uiState.meaningInput.isNotEmpty()
            ) {
                Text(
                    "Save",
                    color = MaterialTheme.colorScheme.primary,
                    style = Typography.titleLarge
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                // Idiom input
                OutlinedTextField(
                    value = uiState.idiomInput,
                    onValueChange = { viewModel.setIdiomInput(it) },
                    label = { Text("Idiom") },
                    placeholder = { Text("Enter the idiom") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
            
            item {
                // Meaning input
                OutlinedTextField(
                    value = uiState.meaningInput,
                    onValueChange = { viewModel.setMeaningInput(it) },
                    label = { Text("Meaning") },
                    placeholder = { Text("Enter the meaning") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5
                )
            }
            
            item {
                // Examples input
                OutlinedTextField(
                    value = uiState.examplesInput,
                    onValueChange = { viewModel.setExamplesInput(it) },
                    label = { Text("Examples (optional)") },
                    placeholder = { Text("Enter example sentences, one per line") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5
                )
            }
        }
    }

    // Error Dialog
    uiState.error?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
}

data class AddIdiomUiState(
    val idiomInput: String = "",
    val meaningInput: String = "",
    val examplesInput: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
) 