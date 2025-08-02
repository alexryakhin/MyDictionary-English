package com.dor.mydictionary.ui.views

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.Divider
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun <T> ListWithDivider(
    items: List<T>,
    modifier: Modifier,
    dividerStartIndent: Dp = 16.dp,
    contentPadding: PaddingValues = PaddingValues(0.dp),
    itemContent: @Composable (T) -> Unit
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = contentPadding
    ) {
        itemsIndexed(items) { index, item ->
            Column {
                itemContent(item)

                if (index < items.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = dividerStartIndent)
                    )
                }
            }
        }
    }
}