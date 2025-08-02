package com.dor.mydictionary.ui.views

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.ImeAction

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ClearTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier, // Add a modifier parameter for flexibility
    singleLine: Boolean = true,
    doneButton: ImeAction = ImeAction.Done,
    onDone: (() -> Unit)? = null
) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        textStyle = LocalTextStyle.current.copy(
            color = MaterialTheme.colorScheme.onSurface
        ),
        cursorBrush = SolidColor(MaterialTheme.colorScheme.onSurface),
        decorationBox = { innerTextField ->
            if (value.isEmpty()) {
                androidx.compose.material3.Text(
                    text = placeholder,
                    style = LocalTextStyle.current,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
            innerTextField() // This is where the actual text field content is rendered
        },
        singleLine = singleLine,
        modifier = modifier.fillMaxWidth(), // Apply the modifier
        keyboardOptions = KeyboardOptions.Default.copy(imeAction = doneButton),
        keyboardActions = KeyboardActions(
            onDone = {
                onDone?.invoke()
            }
        )
    )
}