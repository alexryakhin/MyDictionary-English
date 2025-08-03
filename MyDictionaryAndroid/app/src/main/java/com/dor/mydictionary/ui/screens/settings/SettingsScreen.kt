package com.dor.mydictionary.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.dor.mydictionary.ui.theme.Typography
import com.dor.mydictionary.ui.views.TTSLanguagePickerDialog
import com.dor.mydictionary.ui.views.TTSLanguage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateToTagManagement: () -> Unit = {},
    onNavigateToAbout: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = SettingsUiState())
    var showTTSLanguagePicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadSettings()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings", style = Typography.displaySmall) }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Notification Settings Section
            item {
                NotificationSettingsSection(
                    dailyRemindersEnabled = uiState.dailyRemindersEnabled,
                    difficultWordsAlertsEnabled = uiState.difficultWordsAlertsEnabled,
                    onDailyRemindersToggled = { viewModel.setDailyRemindersEnabled(it) },
                    onDifficultWordsAlertsToggled = { viewModel.setDifficultWordsAlertsEnabled(it) }
                )
            }

            // Practice Settings Section
            item {
                PracticeSettingsSection(
                    practiceWordCount = uiState.practiceWordCount,
                    practiceHardWordsOnly = uiState.practiceHardWordsOnly,
                    hasHardWords = uiState.hasHardWords,
                    onPracticeWordCountChanged = { viewModel.setPracticeWordCount(it) },
                    onPracticeHardWordsOnlyToggled = { viewModel.setPracticeHardWordsOnly(it) }
                )
            }

            // Tag Management Section
            item {
                TagManagementSection(
                    onTagManagementTapped = onNavigateToTagManagement
                )
            }

            // Voice Accent Section
            item {
                VoiceAccentSection(
                    selectedTTSLanguage = uiState.selectedTTSLanguage,
                    onTTSLanguagePickerTapped = { showTTSLanguagePicker = true }
                )
            }

            // Import/Export Section
            item {
                ImportExportSection(
                    onImportWords = { viewModel.importWords() },
                    onExportWords = { viewModel.exportWords() }
                )
            }

            // About Section
            item {
                AboutSection(
                    onAboutTapped = onNavigateToAbout
                )
            }
        }
    }

    // TTS Language Picker Dialog
    if (showTTSLanguagePicker) {
        val selectedLanguage = TTSLanguage.fromCode(uiState.selectedTTSLanguage)
        TTSLanguagePickerDialog(
            languages = TTSLanguage.values().toList(),
            selectedLanguage = selectedLanguage,
            onLanguageSelected = { language ->
                viewModel.setSelectedTTSLanguage(language.code)
            },
            onDismiss = { showTTSLanguagePicker = false }
        )
    }

    // Export Dialog
    if (uiState.shouldShowExportDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.clearExportDialog() },
            title = { Text("Export Words") },
            text = { 
                Text(
                    "CSV content generated successfully. " +
                    "Copy this content and save it as a .csv file:\n\n" +
                    uiState.exportCsvContent?.take(500) + 
                    if ((uiState.exportCsvContent?.length ?: 0) > 500) "..." else ""
                )
            },
            confirmButton = {
                TextButton(onClick = { viewModel.clearExportDialog() }) {
                    Text("OK")
                }
            }
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
private fun NotificationSettingsSection(
    dailyRemindersEnabled: Boolean,
    difficultWordsAlertsEnabled: Boolean,
    onDailyRemindersToggled: (Boolean) -> Unit,
    onDifficultWordsAlertsToggled: (Boolean) -> Unit
) {
    SettingsSection(
        title = "Notifications"
    ) {
        SettingsRow(
            title = "Daily Reminders",
            subtitle = "Get reminded to practice daily",
            icon = Icons.Default.Notifications,
            trailing = {
                Switch(
                    checked = dailyRemindersEnabled,
                    onCheckedChange = onDailyRemindersToggled
                )
            }
        )
        
        SettingsRow(
            title = "Difficult Words Alerts",
            subtitle = "Get notified about words that need review",
            icon = Icons.Default.Warning,
            trailing = {
                Switch(
                    checked = difficultWordsAlertsEnabled,
                    onCheckedChange = onDifficultWordsAlertsToggled
                )
            }
        )
    }
}

@Composable
private fun PracticeSettingsSection(
    practiceWordCount: Int,
    practiceHardWordsOnly: Boolean,
    hasHardWords: Boolean,
    onPracticeWordCountChanged: (Int) -> Unit,
    onPracticeHardWordsOnlyToggled: (Boolean) -> Unit
) {
    SettingsSection(
        title = "Practice Settings"
    ) {
        SettingsRow(
            title = "Words per session",
            subtitle = "Number of words to practice in each session",
            icon = Icons.Default.TextIncrease,
            trailing = {
                Text(
                    text = "$practiceWordCount",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Medium
                )
            }
        )
        
        Column(
            modifier = Modifier.padding(horizontal = 16.dp)
        ) {
            Slider(
                value = practiceWordCount.toFloat(),
                onValueChange = { onPracticeWordCountChanged(it.toInt()) },
                valueRange = 5f..50f,
                steps = 8 // 5, 10, 15, 20, 25, 30, 35, 40, 45, 50
            )
        }
        
        SettingsRow(
            title = "Practice hard words only",
            subtitle = "Focus on words that need review",
            icon = Icons.Default.Star,
            trailing = {
                Switch(
                    checked = practiceHardWordsOnly,
                    onCheckedChange = onPracticeHardWordsOnlyToggled,
                    enabled = hasHardWords
                )
            }
        )
    }
}

@Composable
private fun TagManagementSection(
    onTagManagementTapped: () -> Unit
) {
    SettingsSection(
        title = "Tag Management"
    ) {
        SettingsRow(
            title = "Manage Tags",
            subtitle = "Create, edit, and organize your tags",
            icon = Icons.Default.Tag,
            onClick = onTagManagementTapped
        )
    }
}

@Composable
private fun VoiceAccentSection(
    selectedTTSLanguage: String,
    onTTSLanguagePickerTapped: () -> Unit
) {
    SettingsSection(
        title = "Voice over accent"
    ) {
        SettingsRow(
            title = "Selected Accent",
            subtitle = selectedTTSLanguage,
            icon = Icons.Default.RecordVoiceOver,
            trailing = {
                Icon(
                    Icons.Default.ArrowDropDown,
                    contentDescription = "Select accent"
                )
            },
            onClick = onTTSLanguagePickerTapped
        )
    }
}

@Composable
private fun ImportExportSection(
    onImportWords: () -> Unit,
    onExportWords: () -> Unit
) {
    SettingsSection(
        title = "Import / Export",
        footer = "Please note that import and export only work with files created by this app."
    ) {
        SettingsRow(
            title = "Import words",
            subtitle = "Import words from CSV file",
            icon = Icons.Default.FileDownload,
            onClick = onImportWords
        )
        
        SettingsRow(
            title = "Export words",
            subtitle = "Export words to CSV file",
            icon = Icons.Default.FileUpload,
            onClick = onExportWords
        )
    }
}

@Composable
private fun AboutSection(
    onAboutTapped: () -> Unit
) {
    SettingsSection(
        title = "About app"
    ) {
        SettingsRow(
            title = "About app",
            subtitle = "Learn more about the app",
            icon = Icons.Default.Info,
            onClick = onAboutTapped
        )
    }
}

@Composable
private fun SettingsSection(
    title: String,
    footer: String? = null,
    content: @Composable () -> Unit
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
                text = title,
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            content()
            
            footer?.let {
                Text(
                    text = it,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun SettingsRow(
    title: String,
    subtitle: String? = null,
    icon: ImageVector? = null,
    trailing: @Composable (() -> Unit)? = null,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .then(
                if (onClick != null) {
                    Modifier.clickable { onClick() }
                } else {
                    Modifier
                }
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        icon?.let {
            Icon(
                imageVector = it,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(12.dp))
        }
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = Typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            subtitle?.let {
                Text(
                    text = it,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        trailing?.invoke()
    }
}

data class SettingsUiState(
    val dailyRemindersEnabled: Boolean = false,
    val difficultWordsAlertsEnabled: Boolean = false,
    val practiceWordCount: Int = 10,
    val practiceHardWordsOnly: Boolean = false,
    val hasHardWords: Boolean = false,
    val selectedTTSLanguage: String = "English (US)",
    val isLoading: Boolean = false,
    val error: String? = null,
    val shouldShowExportDialog: Boolean = false,
    val exportCsvContent: String? = null
) 