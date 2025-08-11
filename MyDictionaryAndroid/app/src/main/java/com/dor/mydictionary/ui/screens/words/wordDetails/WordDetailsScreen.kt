package com.dor.mydictionary.ui.screens.words.wordDetails

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Difficulty
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Tag
import com.dor.mydictionary.core.TagColor
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.WordTagCrossRef
import com.dor.mydictionary.ui.views.CellWrapper

@Composable
fun WordDetailsScreen(
    wordId: String,
    onNavigateBack: () -> Unit,
    onNavigateToAddWord: () -> Unit,
    viewModel: WordDetailsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = WordDetailsUiState())
    
    LaunchedEffect(wordId) {
        viewModel.loadWord(wordId)
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Word Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.toggleFavorite() }) {
                        Icon(
                            if (uiState.word?.isFavorite == true) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Toggle Favorite"
                        )
                    }
                    IconButton(onClick = onNavigateToAddWord) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit Word")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            uiState.word?.let { word ->
                item {
                    WordHeaderSection(word = word, onPlayPronunciation = { viewModel.playPronunciation() })
                }
                
                item {
                    DifficultySection(
                        difficulty = word.difficultyLevel,
                        score = word.difficultyScore
                    )
                }
                
                item {
                    TagsSection(
                        tags = uiState.tags,
                        onAddTag = { viewModel.showAddTagDialog() },
                        onRemoveTag = { viewModel.removeTag(it) }
                    )
                }
                
                item {
                    DefinitionsSection(definitions = listOf(word.definition))
                }
                
                if (word.examples.isNotEmpty()) {
                    item {
                        ExamplesSection(examples = word.examples)
                    }
                }
            }
            
            if (uiState.isLoading) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
            }
            
            if (uiState.error != null) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                    ) {
                        Text(
                            text = uiState.error!!,
                            modifier = Modifier.padding(16.dp),
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }
        }
    }
    
    // Add Tag Dialog
    if (uiState.showingAddTagDialog) {
        AddTagDialog(
            onDismiss = { viewModel.hideAddTagDialog() },
            onAddTag = { tagName, tagColor -> viewModel.addTag(tagName, tagColor) }
        )
    }
}

@Composable
private fun WordHeaderSection(
    word: Word,
    onPlayPronunciation: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = word.wordItself,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
                
                if (word.phonetic != null) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = word.phonetic,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        IconButton(onClick = onPlayPronunciation) {
                            Icon(Icons.Default.VolumeUp, contentDescription = "Play Pronunciation")
                        }
                    }
                }
            }
            
            if (word.partOfSpeech != PartOfSpeech.Unknown) {
                Text(
                    text = word.partOfSpeech.rawValue,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
private fun DifficultySection(
    difficulty: Difficulty,
    score: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Difficulty",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    verticalAlignment = Alignment.Start,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        DifficultyChip(difficulty = difficulty)
                        Text(
                            text = difficulty.displayName,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                    
                    Text(
                        text = "Score: $score", // This will need to be updated to show actual score
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Text(
                    text = "Quiz-based",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun TagsSection(
    tags: List<Tag>,
    onAddTag: () -> Unit,
    onRemoveTag: (Tag) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Tags",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                TextButton(onClick = onAddTag) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Add Tag")
                }
            }
            
            if (tags.isEmpty()) {
                Text(
                    text = "No tags added yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    tags.forEach { tag ->
                        TagChip(
                            tag = tag,
                            onRemove = { onRemoveTag(tag) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DefinitionsSection(definitions: List<String>) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Definitions",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            definitions.forEachIndexed { index, definition ->
                Text(
                    text = "${index + 1}. $definition",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
private fun ExamplesSection(examples: List<String>) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Examples",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            examples.forEachIndexed { index, example ->
                Text(
                    text = "${index + 1}. $example",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun DifficultyChip(difficulty: Difficulty) {
    Surface(
        shape = MaterialTheme.shapes.small,
        color = difficulty.color,
        modifier = Modifier.padding(horizontal = 4.dp)
    ) {
        Text(
            text = difficulty.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimary,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Composable
private fun TagChip(
    tag: Tag,
    onRemove: () -> Unit
) {
    Surface(
        shape = MaterialTheme.shapes.small,
        color = tag.color.toColor(),
        modifier = Modifier.padding(horizontal = 4.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                text = tag.name,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onPrimary
            )
            Spacer(modifier = Modifier.width(4.dp))
            IconButton(
                onClick = onRemove,
                modifier = Modifier.size(16.dp)
            ) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Remove tag",
                    modifier = Modifier.size(12.dp),
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        }
    }
}

@Composable
private fun AddTagDialog(
    onDismiss: () -> Unit,
    onAddTag: (String, TagColor) -> Unit
) {
    var tagName by remember { mutableStateOf("") }
    var selectedColor by remember { mutableStateOf(TagColor.Blue) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Tag") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = tagName,
                    onValueChange = { tagName = it },
                    label = { Text("Tag Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                Text(
                    text = "Color",
                    style = MaterialTheme.typography.titleSmall
                )
                
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(TagColor.entries.toList()) { color ->
                        Surface(
                            shape = MaterialTheme.shapes.small,
                            color = color.toColor(),
                            modifier = Modifier
                                .size(32.dp)
                                .clickable { selectedColor = color }
                        ) {
                            if (selectedColor == color) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = "Selected",
                                    tint = MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.padding(4.dp)
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (tagName.isNotBlank()) {
                        onAddTag(tagName, selectedColor)
                        onDismiss()
                    }
                }
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

private fun TagColor.toColor(): androidx.compose.ui.graphics.Color {
    return when (this) {
        TagColor.Red -> androidx.compose.ui.graphics.Color(0xFFE57373)
        TagColor.Pink -> androidx.compose.ui.graphics.Color(0xFFF06292)
        TagColor.Purple -> androidx.compose.ui.graphics.Color(0xFFBA68C8)
        TagColor.Blue -> androidx.compose.ui.graphics.Color(0xFF64B5F6)
        TagColor.Green -> androidx.compose.ui.graphics.Color(0xFF81C784)
        TagColor.Yellow -> androidx.compose.ui.graphics.Color(0xFFFFF176)
        TagColor.Orange -> androidx.compose.ui.graphics.Color(0xFFFFB74D)
        TagColor.Grey -> androidx.compose.ui.graphics.Color(0xFF90A4AE)
    }
} 