package com.dor.mydictionary.ui.screens.words.addWord

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.FetchingStatus
import com.dor.mydictionary.ui.screens.words.addWord.AddWordViewModel
import com.dor.mydictionary.ui.screens.words.wordsList.WordsListViewModel
import com.dor.mydictionary.ui.views.CellWrapper
import com.dor.mydictionary.ui.views.ClearTextField
import com.dor.mydictionary.ui.views.PartOfSpeechPicker
import com.dor.mydictionary.ui.theme.Typography
import java.util.Date
import java.util.UUID

@Composable
fun AddWordSheet(
    viewModel: AddWordViewModel = hiltViewModel(),
    onDismiss: () -> Unit,
    onSave: (Word) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
            .navigationBarsPadding()
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Add new word", style = Typography.headlineLarge)
            TextButton(
                onClick = {
                    viewModel.saveWord { word ->
                        onSave(word)
                    }
                },
                enabled = viewModel.wordInput.isNotEmpty() && viewModel.definitionInput.isNotEmpty()
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
            // Main form
            item {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column {
                        // Word input
                        CellWrapper<Unit, Unit, Unit>(
                            label = "Word",
                            mainContent = {
                                ClearTextField(
                                    value = viewModel.wordInput,
                                    onValueChange = { viewModel.wordInput = it },
                                    placeholder = "Type a word",
                                    onDone = {
                                        if (viewModel.wordInput.isNotEmpty()) {
                                            viewModel.searchWordnik()
                                        }
                                    }
                                )
                            }
                        )
                        
                        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                        
                        // Definition input
                        CellWrapper<Unit, Unit, Unit>(
                            label = "Definition",
                            mainContent = {
                                ClearTextField(
                                    value = viewModel.definitionInput,
                                    onValueChange = { viewModel.definitionInput = it },
                                    placeholder = "Enter definition",
                                    singleLine = false
                                )
                            }
                        )
                        
                        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                        
                        // Part of speech
                        CellWrapper<Unit, Unit, Unit>(
                            label = "Part of speech",
                            mainContent = {
                                PartOfSpeechPicker(
                                    selected = viewModel.selectedPartOfSpeech,
                                    onSelect = { viewModel.selectedPartOfSpeech = it }
                                )
                            }
                        )
                        
                        HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                        
                        // Phonetics
                        if (viewModel.transcription.isNotEmpty()) {
                            CellWrapper<Unit, Unit, Unit>(
                                label = "Pronunciation",
                                mainContent = {
                                    Text(viewModel.transcription)
                                },
                                trailingContent = {
                                    IconButton(
                                        onClick = { viewModel.playPronunciation() }
                                    ) {
                                        Icon(
                                            Icons.Default.PlayArrow,
                                            contentDescription = "Play pronunciation",
                                            tint = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }
                            )
                            
                            HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                        }
                        
                        // Tags (placeholder for now)
                        CellWrapper<Unit, Unit, Unit>(
                            label = "Tags",
                            mainContent = {
                                Text(
                                    "No tags selected",
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            },
                            trailingContent = {
                                IconButton(
                                    onClick = { /* TODO: Show tag selection */ }
                                ) {
                                    Icon(
                                        Icons.Default.Add,
                                        contentDescription = "Add tag",
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        )
                    }
                }
            }
            
            // Search results section
            item {
                Text(
                    "Select a definition",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
            }
            
            // Search results
            when (viewModel.status) {
                FetchingStatus.Loading -> {
                    item {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceContainer
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text("Loading definitions...")
                                // TODO: Add shimmer effect
                            }
                        }
                    }
                }
                FetchingStatus.Error -> {
                    item {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceContainer
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    "Error Loading Definitions",
                                    style = Typography.titleMedium,
                                    fontWeight = FontWeight.Medium
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    "There is an error loading definitions. Please try again.",
                                    style = Typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Button(
                                    onClick = { viewModel.searchWordnik() },
                                    enabled = viewModel.wordInput.isNotEmpty()
                                ) {
                                    Icon(
                                        Icons.Default.Search,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Retry")
                                }
                            }
                        }
                    }
                }
                FetchingStatus.Ready -> {
                    itemsIndexed(viewModel.wordnikResults) { index, definition ->
                        DefinitionCard(
                            definition = definition,
                            index = index,
                            isSelected = viewModel.selectedDefinitionIndex == index,
                            onSelect = { viewModel.selectDefinition(index, definition) }
                        )
                    }
                }
                FetchingStatus.Blank -> {
                    item {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceContainer
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalArrangement = Arrangement.Center,
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    "Type a word and press 'Search' to find its definitions",
                                    style = Typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Button(
                                    onClick = { viewModel.searchWordnik() },
                                    enabled = viewModel.wordInput.isNotEmpty()
                                ) {
                                    Icon(
                                        Icons.Default.Search,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Search")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DefinitionCard(
    definition: com.dor.mydictionary.services.wordnik.WordnikDefinition,
    index: Int,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect() },
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer
                           else MaterialTheme.colorScheme.surfaceContainer
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        "Definition ${index + 1}, ${definition.partOfSpeech.rawValue}",
                        style = Typography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        definition.definitionText,
                        style = Typography.bodyMedium
                    )
                }
                
                if (isSelected) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = "Selected",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
            }
            
            if (definition.examples.isNotEmpty()) {
                Spacer(modifier = Modifier.height(12.dp))
                definition.examples.forEach { example ->
                    Text(
                        "• $example",
                        style = Typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
            }
        }
    }
}
