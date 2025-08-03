package com.dor.mydictionary.ui.screens.settings.tagManagement

import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Tag
import com.dor.mydictionary.core.TagColor
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TagManagementScreen(
    onNavigateBack: () -> Unit = {},
    viewModel: TagManagementViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = TagManagementUiState())
    var showAddTagDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadTags()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Manage Tags", style = Typography.displaySmall) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showAddTagDialog = true }) {
                        Icon(Icons.Default.Add, contentDescription = "Add Tag")
                    }
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (uiState.tags.isEmpty()) {
                item {
                    EmptyStateView(
                        icon = Icons.Default.Tag,
                        title = "No Tags Yet",
                        subtitle = "Create your first tag to organize your words"
                    )
                }
            } else {
                items(uiState.tags) { tag ->
                    TagItem(
                        tag = tag,
                        onEdit = { viewModel.editTag(tag) },
                        onDelete = { viewModel.deleteTag(tag) }
                    )
                }
            }
        }
    }

    // Add Tag Dialog
    if (showAddTagDialog) {
        AddTagDialog(
            onTagAdded = { name, color ->
                viewModel.addTag(name, color)
                showAddTagDialog = false
            },
            onDismiss = { showAddTagDialog = false }
        )
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

@Composable
private fun TagItem(
    tag: Tag,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Tag color indicator
            Box(
                modifier = Modifier
                    .size(16.dp)
                    .background(
                        color = colorFromTagColor(tag.color),
                        shape = MaterialTheme.shapes.small
                    )
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            // Tag name
            Text(
                text = tag.name,
                style = Typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )
            
            // Action buttons
            IconButton(onClick = onEdit) {
                Icon(Icons.Default.Edit, contentDescription = "Edit")
            }
            
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete")
            }
        }
    }
}

@Composable
private fun EmptyStateView(
    icon: ImageVector,
    title: String,
    subtitle: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Text(
            text = title,
            style = Typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
        
        Text(
            text = subtitle,
            style = Typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 32.dp)
        )
    }
}

@Composable
private fun AddTagDialog(
    onTagAdded: (name: String, color: TagColor) -> Unit,
    onDismiss: () -> Unit
) {
    var tagName by remember { mutableStateOf("") }
    var selectedColor by remember { mutableStateOf(TagColor.Blue) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add New Tag") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = tagName,
                    onValueChange = { tagName = it },
                    label = { Text("Tag Name") },
                    singleLine = true
                )
                
                Text(
                    text = "Select Color",
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(TagColor.values()) { color ->
                        ColorOption(
                            color = color,
                            isSelected = color == selectedColor,
                            onClick = { selectedColor = color }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (tagName.isNotBlank()) {
                        onTagAdded(tagName, selectedColor)
                    }
                },
                enabled = tagName.isNotBlank()
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

@Composable
private fun ColorOption(
    color: TagColor,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(32.dp)
            .background(
                color = colorFromTagColor(color),
                shape = MaterialTheme.shapes.small
            )
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = "Selected",
                tint = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@Composable
private fun colorFromTagColor(tagColor: TagColor): androidx.compose.ui.graphics.Color {
    return when (tagColor) {
        TagColor.Blue -> Color.Blue
        TagColor.Red -> Color.Red
        TagColor.Green -> Color.Green
        TagColor.Orange -> Color(0xFFFF9800)
        TagColor.Purple -> Color.Magenta
        TagColor.Pink -> Color(0xFFE91E63)
        TagColor.Yellow -> Color.Yellow
        TagColor.Grey -> Color.Gray
    }
}