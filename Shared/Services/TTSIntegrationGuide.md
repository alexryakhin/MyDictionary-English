# TTS Integration Guide

## Overview

My Dictionary now supports dual Text-to-Speech (TTS) providers:

1. **Google TTS** (Free) - Basic TTS functionality for all users
2. **Speechify TTS** (Premium) - High-quality AI voices for Pro users

## Architecture

### Core Components

- `TTSProvider.swift` - Provider enum and data models
- `TTSPlayer.swift` - Main TTS player with dual provider support
- `SpeechifyTTSService.swift` - Speechify API integration
- `TTSSettingsView.swift` - User interface for TTS settings
- `SpeechifyConfig.swift` - Configuration and constants

### Key Features

- **Automatic Provider Selection**: Pro users get Speechify, free users get Google TTS
- **Fallback System**: If Speechify fails, automatically falls back to Google TTS
- **Voice Management**: Pro users can choose from multiple Speechify voices
- **Premium Protection**: Non-Pro users cannot access Speechify features

## Usage

### Basic TTS Usage

```swift
// Simple usage - automatically chooses the best provider
try await TTSPlayer.shared.play("Hello world", targetLanguage: "en")

// Check current provider
let currentProvider = TTSPlayer.shared.currentProvider

// Check if playing
let isPlaying = TTSPlayer.shared.isPlaying
```

### Advanced Usage

```swift
// Force specific provider (if user has access)
if SubscriptionService.shared.isProUser {
    UserDefaults.standard.set(TTSProvider.speechify.rawValue, forKey: UDKeys.selectedTTSProvider)
}

// Set specific Speechify voice
UserDefaults.standard.set("en-US-2", forKey: UDKeys.selectedSpeechifyVoice)
```

## Configuration

### Environment Setup

1. **Add Speechify API Key**:
   ```bash
   # Add to your environment variables
   export SPEECHIFY_API_KEY="your_api_key_here"
   ```

2. **For Production**:
   - Store API key securely in Keychain
   - Use proper environment variable management
   - Consider using a configuration service

### API Key Security

```swift
// In production, use Keychain or secure storage
import Security

func getSecureAPIKey() -> String {
    // Implement secure key retrieval
    return KeychainService.shared.getAPIKey(for: "speechify")
}
```

## Error Handling

### Common Errors

```swift
enum TTSError: Error {
    case invalidAPIKey
    case networkError(String)
    case audioError(String)
    case premiumFeatureRequired
    case invalidResponse
    case rateLimitExceeded
}
```

### Error Handling Example

```swift
do {
    try await TTSPlayer.shared.play(text, targetLanguage: language)
} catch TTSError.premiumFeatureRequired {
    // Show upgrade prompt
    showPremiumUpgradeAlert()
} catch TTSError.networkError(let message) {
    // Handle network issues
    showNetworkErrorAlert(message)
} catch {
    // Handle other errors
    showGenericErrorAlert()
}
```

## User Interface

### Settings Integration

Add TTS settings to your settings view:

```swift
NavigationLink("TTS Settings") {
    TTSSettingsView()
}
```

### Premium Indicators

```swift
if provider.isPremium {
    Image(systemName: "crown.fill")
        .foregroundColor(.yellow)
}
```

## Testing

### Test Both Providers

```swift
// Test Google TTS
UserDefaults.standard.set(TTSProvider.google.rawValue, forKey: UDKeys.selectedTTSProvider)
try await TTSPlayer.shared.play("Google TTS test", targetLanguage: "en")

// Test Speechify (requires Pro subscription)
if SubscriptionService.shared.isProUser {
    UserDefaults.standard.set(TTSProvider.speechify.rawValue, forKey: UDKeys.selectedTTSProvider)
    try await TTSPlayer.shared.play("Speechify TTS test", targetLanguage: "en")
}
```

## Monitoring and Analytics

### Usage Tracking

```swift
// Track TTS usage for analytics
AnalyticsService.shared.logEvent(.ttsUsed, parameters: [
    "provider": TTSPlayer.shared.currentProvider.rawValue,
    "language": targetLanguage ?? "unknown",
    "text_length": text.count
])
```

### Billing Monitoring

```swift
// Monitor Speechify usage for billing
if let response = try? await speechifyService.synthesizeSpeech(request) {
    let billableCharacters = response.billableCharacters ?? 0
    // Track for billing purposes
    BillingService.shared.trackSpeechifyUsage(characters: billableCharacters)
}
```

## Best Practices

1. **Always provide fallback**: Use Google TTS as fallback for Speechify failures
2. **Respect rate limits**: Implement proper rate limiting for API calls
3. **Cache responses**: Consider caching frequently used TTS responses
4. **Monitor usage**: Track usage for both providers
5. **User education**: Clearly explain the difference between providers to users

## Troubleshooting

### Common Issues

1. **Speechify not working**:
   - Check API key configuration
   - Verify Pro subscription status
   - Check network connectivity

2. **Google TTS fallback not working**:
   - Verify internet connection
   - Check if Google TTS service is available

3. **Voice selection issues**:
   - Ensure voices are loaded before allowing selection
   - Handle voice loading errors gracefully

### Debug Mode

```swift
// Enable debug logging
#if DEBUG
print("TTS Provider: \(TTSPlayer.shared.currentProvider)")
print("Available Voices: \(TTSPlayer.shared.availableVoices.count)")
#endif
```
