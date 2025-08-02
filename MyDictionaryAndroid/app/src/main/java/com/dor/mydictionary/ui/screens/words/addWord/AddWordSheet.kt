import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.FetchingStatus
import com.dor.mydictionary.ui.screens.words.addWord.AddWordViewModel
import com.dor.mydictionary.ui.screens.words.wordsList.WordsListViewModel
import com.dor.mydictionary.ui.views.CellWrapper
import com.dor.mydictionary.ui.views.ClearTextField
import com.dor.mydictionary.ui.theme.Typography
import java.util.Date
import java.util.UUID

@Composable
fun AddWordSheet(
    viewModel: AddWordViewModel = hiltViewModel(),
    onDismiss: () -> Unit,
    onSave: (Word) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
            .navigationBarsPadding()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom
        ) {
            Text("Add new word", style = Typography.headlineLarge)
            TextButton(
                onClick = {
                    viewModel.saveWord { word ->
                        onSave(word)
                    }
                }, content = {
                    Text(
                        "Save",
                        color = MaterialTheme.colorScheme.primary,
                        style = Typography.titleLarge
                    )
                }
            )
        }
        LazyColumn(
            modifier = Modifier
                .padding(top = 12.dp)
                .fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Column(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceContainer)
                ) {
                    CellWrapper<Unit, Unit, Unit>(
                        label = "Word",
                        mainContent = {
                            ClearTextField(
                                value = viewModel.wordInput,
                                onValueChange = { viewModel.wordInput = it },
                                placeholder = "Type a word",
                                onDone = {
                                    viewModel.searchWordnik()
                                }
                            )
                        }
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 8.dp))

                    CellWrapper<Unit, Unit, Unit>(
                        label = "Definition",
                        mainContent = {
                            ClearTextField(
                                value = viewModel.definitionInput,
                                onValueChange = { viewModel.definitionInput = it },
                                placeholder = "Enter definition",
                                singleLine = false
                            )
                        }
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))

                    CellWrapper<Unit, Unit, Unit>(
                        label = "Part of speech",
                        mainContent = {
                            PartOfSpeechPicker(
                                selected = viewModel.selectedPartOfSpeech,
                                onSelect = { viewModel.selectedPartOfSpeech = it }
                            )
                        }
                    )
                }
                // TODO: Add pronunciation + search result section
            }

            item {
                Spacer(modifier = Modifier.height(8.dp))
            }

            when (viewModel.status) {
                FetchingStatus.Loading -> {
                    item {
                        Text("Loading definitions...")
                    }
                }
                FetchingStatus.Error -> {
                    item {
                        Text("Error fetching definitions")
                    }
                }
                FetchingStatus.Ready -> {
                    itemsIndexed(viewModel.wordnikResults) { index, definition ->
                        Column(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.surfaceContainer)
                                .fillMaxWidth()
                        ) {
                            CellWrapper<Unit, Unit, Unit>(
                                label = "Definition ${index + 1}, ${definition.partOfSpeech.rawValue}",
                                mainContent = {
                                    Text(definition.definitionText)
                                }
                            )

                            definition.examples.forEach { example ->
                                HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                                CellWrapper<Unit, Unit, Unit>(
                                    label = "Example",
                                    mainContent = {
                                        Text(example)
                                    }
                                )
                            }
                        }
                    }
                }
                FetchingStatus.Blank -> {
                    item {
                        Column(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.surfaceContainer)
                                .fillMaxWidth()
                                .height(150.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("Input a word to search")
                            TextButton(
                                onClick = { viewModel.searchWordnik() },
                                enabled = viewModel.wordInput.isNotEmpty()
                            ) {
                                Text("Search")
                            }
                        }
                    }
                }
            }
        }
    }
}
