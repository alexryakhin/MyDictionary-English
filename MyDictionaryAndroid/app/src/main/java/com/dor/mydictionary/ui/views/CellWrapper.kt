package com.dor.mydictionary.ui.views

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun <Leading, Main, Trailing> CellWrapper(
    label: String? = null, // Use resource ID for localized string
    leadingContent: @Composable (() -> Leading)? = null,
    mainContent: @Composable () -> Main,
    trailingContent: @Composable (() -> Trailing)? = null,
    onTapAction: (() -> Unit)? = null,
    isEnabled: Boolean = true,
) {
    val interactionSource = remember { MutableInteractionSource() }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(
                enabled = isEnabled,
                onClick = { onTapAction?.invoke() },
                indication = null, // Remove ripple effect for closer match to SwiftUI
                interactionSource = interactionSource
            )
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp
            )
            .alpha(if (isEnabled) 1f else 0.4f),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        leadingContent?.let {
            leadingContent()
        }

        Column(
            modifier = Modifier
                .weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalAlignment = Alignment.Start
        ) {
            label?.let {
                CompositionLocalProvider(LocalContentColor provides MaterialTheme.colorScheme.onSurfaceVariant) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelSmall,
                        color = LocalContentColor.current,
                        textAlign = TextAlign.Start
                    )
                }
            }
            mainContent()
        }

        trailingContent?.let {
            trailingContent()
        }
    }
}

// Example usage (replace with your actual content):
@Composable
fun ExampleCell() {
    CellWrapper(
        label = "Label", // Example string resource
        leadingContent = { /* Replace with your leading content, e.g., Icon */ },
        mainContent = {
            Text(
                "Main Content Here",
                style = MaterialTheme.typography.bodyLarge
            )
        },
        trailingContent = { /* Replace with your trailing content, e.g., Icon or Text */ },
        onTapAction = { /* Handle tap */ },
        isEnabled = true
    )
}