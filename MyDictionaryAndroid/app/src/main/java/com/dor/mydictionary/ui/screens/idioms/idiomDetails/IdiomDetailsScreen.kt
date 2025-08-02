package com.dor.mydictionary.ui.screens.idioms.idiomDetails

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.dor.mydictionary.core.Idiom
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IdiomDetailsScreen(
    idiomId: String,
    onNavigateBack: () -> Unit,
    onNavigateToAddIdiom: () -> Unit,
    viewModel: IdiomDetailsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = IdiomDetailsUiState())
    
    LaunchedEffect(idiomId) {
        viewModel.loadIdiom(idiomId)
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Idiom Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.toggleFavorite() }) {
                        Icon(
                            if (uiState.idiom?.isFavorite == true) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Toggle Favorite"
                        )
                    }
                    IconButton(onClick = onNavigateToAddIdiom) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit Idiom")
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
            uiState.idiom?.let { idiom ->
                item {
                    IdiomHeaderSection(idiom = idiom)
                }
                
                item {
                    MeaningSection(meaning = idiom.definition)
                }
                
                if (idiom.examples.isNotEmpty()) {
                    item {
                        ExamplesSection(examples = idiom.examples)
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
}

@Composable
private fun IdiomHeaderSection(idiom: Idiom) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = idiom.idiomItself,
                style = Typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (idiom.isFavorite) {
                    Icon(
                        Icons.Default.Favorite,
                        contentDescription = "Favorite",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                }
                
                Text(
                    text = "Added ${idiom.timestamp.toString().split(" ").take(3).joinToString(" ")}",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun MeaningSection(meaning: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Meaning",
                style = Typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = meaning,
                style = Typography.bodyMedium
            )
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
                style = Typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            examples.forEachIndexed { index, example ->
                Text(
                    text = "${index + 1}. $example",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

data class IdiomDetailsUiState(
    val idiom: Idiom? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) 