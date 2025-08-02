package com.dor.mydictionary.ui.screens.words.wordsList

import AddWordSheet
import android.graphics.drawable.Icon
import android.util.Log
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word
import java.util.Date
import java.util.UUID
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButtonDefaults.Icon
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import com.dor.mydictionary.ui.views.ListWithDivider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.font.FontWeight
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WordsListScreen(
    viewModel: WordsListViewModel = hiltViewModel()
) {
    val words by viewModel.uiState.collectAsState()
    var showAddWordDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Words", style = Typography.displaySmall) },
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddWordDialog = true }
            ) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = "Add Word"
                )
            }
        },
        modifier = Modifier
            .background(MaterialTheme.colorScheme.background)
    ) { innerPadding ->
        ListWithDivider(
            modifier = Modifier
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surfaceContainer),
            items = words
        ) { word ->
            WordRow(word, onClick = {
                Log.d("${word.wordItself} Word tapped", "DEBUG50")
            }, onFavoriteClick = {
                Log.d("${word.wordItself} Favorite clicked", "DEBUG50")
                viewModel.toggleFavorite(word.id)
            }, onDeleteClick = {
                Log.d("${word.wordItself} Delete clicked", "DEBUG50")
                viewModel.removeWord(word.id)
            })
        }
    }

    if (showAddWordDialog) {
        ModalBottomSheet(
            modifier = Modifier
                .statusBarsPadding(),
            onDismissRequest = { showAddWordDialog = false },
            sheetState = rememberModalBottomSheetState(
                skipPartiallyExpanded = true
            )
        ) {
            AddWordSheet(
                onDismiss = { showAddWordDialog = false },
                onSave = { word ->
                    viewModel.addWord(word)
                    showAddWordDialog = false
                }
            )
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun WordRow(
    word: Word,
    onClick: () -> Unit,
    onFavoriteClick: () -> Unit,
    onDeleteClick: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Box(modifier = Modifier
        .fillMaxWidth()
        .combinedClickable(
            onClick = { onClick() },
            onLongClick = { showMenu = true }
        )
        .padding(
            vertical = 12.dp,
            horizontal = 16.dp
        )
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                modifier = Modifier.weight(1f),
                text = word.wordItself,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            if (word.isFavorite) {
                Icon(
                    Icons.Default.Bookmark,
                    contentDescription = "BookmarkImage",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = "ChevronRightImage",
                tint = MaterialTheme.colorScheme.onSurface
            )
        }

        DropdownMenu(
            expanded = showMenu,
            onDismissRequest = { showMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text(if (word.isFavorite) "Unfavorite" else "Favorite") },
                onClick = {
                    showMenu = false
                    onFavoriteClick()
                }
            )
            DropdownMenuItem(
                text = { Text("Delete") },
                onClick = {
                    showMenu = false
                    onDeleteClick()
                }
            )
        }
    }
}