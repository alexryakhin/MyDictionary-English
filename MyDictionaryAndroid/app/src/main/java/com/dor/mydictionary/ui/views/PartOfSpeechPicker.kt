import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.dor.mydictionary.core.PartOfSpeech

@Composable
fun PartOfSpeechPicker(
    selected: PartOfSpeech,
    onSelect: (PartOfSpeech) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true }
        ) {
            Text(
                text = if (selected == PartOfSpeech.Unknown) "Select a value" else "${selected.rawValue}",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.primary
            )
        }

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            PartOfSpeech.entries.forEach { part ->
                DropdownMenuItem(
                    text = { Text(part.rawValue) },
                    onClick = {
                        onSelect(part)
                        expanded = false
                    }
                )
            }
        }
    }
}