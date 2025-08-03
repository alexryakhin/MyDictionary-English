package com.dor.mydictionary.ui.screens.settings

import android.Manifest
import android.content.pm.PackageManager
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.ui.platform.LocalContext
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
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
    val context = LocalContext.current

    // Permission launcher for storage access
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        android.util.Log.d("SettingsScreen", "Permission result: $isGranted")
        if (isGranted) {
            android.util.Log.d("SettingsScreen", "Permission granted, calling importWords")
            viewModel.importWords()
        } else {
            android.util.Log.d("SettingsScreen", "Permission denied")
        }
    }

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
                    onImportWords = { 
                        android.util.Log.d("SettingsScreen", "Import button tapped!")
                        
                        // Check if we're on Android 13+ (API 33+)
                        val isAndroid13Plus = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU
                        android.util.Log.d("SettingsScreen", "Android version: ${android.os.Build.VERSION.SDK_INT}, isAndroid13Plus: $isAndroid13Plus")
                        
                        if (isAndroid13Plus) {
                            // For Android 13+, file picker handles permissions automatically
                            android.util.Log.d("SettingsScreen", "Android 13+, calling importWords directly")
                            viewModel.importWords()
                        } else {
                            // For older versions, check permission first
                            val hasPermission = ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.READ_EXTERNAL_STORAGE
                            ) == PackageManager.PERMISSION_GRANTED
                            
                            android.util.Log.d("SettingsScreen", "Older Android, has permission: $hasPermission")
                            
                            if (hasPermission) {
                                android.util.Log.d("SettingsScreen", "Permission granted, calling importWords")
                                viewModel.importWords()
                            } else {
                                android.util.Log.d("SettingsScreen", "Requesting permission")
                                permissionLauncher.launch(Manifest.permission.READ_EXTERNAL_STORAGE)
                            }
                        }
                    },
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

    // File Picker Launchers
    val importLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        android.util.Log.d("SettingsScreen", "Import launcher callback. URI: $uri")
        // Check if the selected file is a CSV file
        if (uri != null) {
            val fileName = uri.lastPathSegment ?: ""
            val uriString = uri.toString()
            android.util.Log.d("SettingsScreen", "Selected file: $fileName")
            android.util.Log.d("SettingsScreen", "Full URI: $uriString")
            
            // Accept any file and let the CSV parser validate the content
            android.util.Log.d("SettingsScreen", "Accepting any file, calling handleImportFileSelected")
            viewModel.handleImportFileSelected(uri)
        } else {
            android.util.Log.d("SettingsScreen", "No URI selected, calling handleImportFileSelected with null")
            viewModel.handleImportFileSelected(null)
        }
    }

    val exportLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("text/csv")
    ) { uri ->
        viewModel.handleExportFileSelected(uri)
    }

    // Launch file pickers when needed
    LaunchedEffect(uiState.shouldShowImportPicker) {
        android.util.Log.d("SettingsScreen", "LaunchedEffect triggered. shouldShowImportPicker: ${uiState.shouldShowImportPicker}")
        if (uiState.shouldShowImportPicker) {
            android.util.Log.d("SettingsScreen", "Launching import launcher")
            importLauncher.launch("*/*")
        }
    }

    LaunchedEffect(uiState.shouldShowExportPicker) {
        if (uiState.shouldShowExportPicker) {
            exportLauncher.launch("MyDictionaryExport.csv")
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
    val exportCsvContent: String? = null,
    val shouldShowImportPicker: Boolean = false,
    val shouldShowExportPicker: Boolean = false
) 