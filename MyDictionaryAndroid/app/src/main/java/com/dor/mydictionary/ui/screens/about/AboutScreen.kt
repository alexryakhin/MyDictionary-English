package com.dor.mydictionary.ui.screens.about

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(
    onNavigateBack: () -> Unit = {},
    viewModel: AboutViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = AboutUiState())

    LaunchedEffect(Unit) {
        viewModel.loadAppInfo()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("About", style = Typography.displaySmall) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
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
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // App Info Section
            item {
                AppInfoSection(
                    appName = uiState.appName,
                    appVersion = uiState.appVersion,
                    buildNumber = uiState.buildNumber
                )
            }

            // About Description Section
            item {
                AboutDescriptionSection()
            }

            // Features Section
            item {
                FeaturesSection()
            }

            // Contact Section
            item {
                ContactSection(viewModel)
            }

            // Support Section
            item {
                SupportSection(viewModel)
            }
        }
    }
}

@Composable
private fun AppInfoSection(
    appName: String,
    appVersion: String,
    buildNumber: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Book,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = appName,
                style = Typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "Version $appVersion ($buildNumber)",
                style = Typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun AboutDescriptionSection() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "About app",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "I created this app because I could not find something that I wanted.\n\n" +
                       "It is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.\n\n" +
                       "I find this best to learn English. Hope it will work for you as well.\n\n" +
                       "If you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!",
                style = Typography.bodyMedium,
                textAlign = TextAlign.Start
            )
        }
    }
}

@Composable
private fun FeaturesSection() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Features",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            val features = listOf(
                "Add and organize words with definitions",
                "Practice with quizzes and spelling exercises",
                "Track your learning progress",
                "Import and export your word collection",
                "Customize your learning experience",
                "Voice pronunciation support"
            )
            
            features.forEach { feature ->
                Row(
                    modifier = Modifier.padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = feature,
                        style = Typography.bodyMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun ContactSection(viewModel: AboutViewModel) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Contact me",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!",
                style = Typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Twitter/X Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.openTwitter() }
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Share,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "X (Twitter)",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.OpenInNew,
                    contentDescription = "Open link",
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Instagram Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.openInstagram() }
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.CameraAlt,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Instagram",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.OpenInNew,
                    contentDescription = "Open link",
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun SupportSection(viewModel: AboutViewModel) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Support",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Buy Me a Coffee Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.openBuyMeACoffee() }
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Favorite,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color(0xFFFF6B35) // Orange color for coffee
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Buy Me a Coffee",
                    style = Typography.bodyMedium,
                    color = Color(0xFFFF6B35)
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.OpenInNew,
                    contentDescription = "Open link",
                    modifier = Modifier.size(16.dp),
                    tint = Color(0xFFFF6B35)
                )
            }
            
            // Rate the App Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.openAppStoreRating() }
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color(0xFFFFD700) // Gold color for star
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Rate the app",
                    style = Typography.bodyMedium,
                    color = Color(0xFFFFD700)
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.OpenInNew,
                    contentDescription = "Open link",
                    modifier = Modifier.size(16.dp),
                    tint = Color(0xFFFFD700)
                )
            }
        }
    }
}

data class AboutUiState(
    val appName: String = "My Dictionary",
    val appVersion: String = "1.0.0",
    val buildNumber: String = "1",
    val isLoading: Boolean = false,
    val error: String? = null
) 