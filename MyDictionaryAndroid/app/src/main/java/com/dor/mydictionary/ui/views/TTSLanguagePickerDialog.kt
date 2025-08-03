package com.dor.mydictionary.ui.views

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dor.mydictionary.ui.theme.Typography

@Composable
fun TTSLanguagePickerDialog(
    languages: List<TTSLanguage>,
    selectedLanguage: TTSLanguage,
    onLanguageSelected: (TTSLanguage) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Select Voice Accent",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
        },
        text = {
            LazyColumn {
                items(languages) { language ->
                    LanguageOption(
                        language = language,
                        isSelected = language == selectedLanguage,
                        onClick = {
                            onLanguageSelected(language)
                            onDismiss()
                        }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun LanguageOption(
    language: TTSLanguage,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp, horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = language.title,
                style = Typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = language.subtitle,
                style = Typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = "Selected",
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

enum class TTSLanguage(
    val title: String,
    val subtitle: String,
    val code: String
) {
    EN_US("English (US)", "American accent", "en-US"),
    EN_GB("English (UK)", "British accent", "en-GB"),
    EN_AU("English (Australia)", "Australian accent", "en-AU"),
    EN_CA("English (Canada)", "Canadian accent", "en-CA"),
    EN_IN("English (India)", "Indian accent", "en-IN"),
    EN_IE("English (Ireland)", "Irish accent", "en-IE"),
    EN_NZ("English (New Zealand)", "New Zealand accent", "en-NZ"),
    EN_ZA("English (South Africa)", "South African accent", "en-ZA");
    
    companion object {
        fun fromCode(code: String): TTSLanguage {
            return values().find { it.code == code } ?: EN_US
        }
    }
} 