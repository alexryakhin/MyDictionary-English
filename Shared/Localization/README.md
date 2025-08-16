# Localization System

This directory contains the localization system for the My Dictionary app. The system provides a centralized way to manage all user-facing strings in the app.

## Structure

- `Loc.swift` - Enum containing all localization keys as static properties
- `String+Localization.swift` - Extension providing convenient access to localized strings
- `en.lproj/Localizable.strings` - English localization strings
- `ru.lproj/Localizable.strings` - Russian localization strings

## Usage

### Basic Usage

Instead of hardcoding strings in your SwiftUI views, use the `Loc` enum:

```swift
// Before
Text("Words")

// After
Text(Loc.words.localized)
```

### With Format Arguments

For strings that need dynamic values:

```swift
// Before
Text("\(count) words")

// After
Text(Loc.wordsCount.localized(count))
```

### In SwiftUI Views

```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text(Loc.welcomeTo.localized)
            Text(Loc.myDictionary.localized)
            
            Button(Loc.getStarted.localized) {
                // Action
            }
        }
        .navigationTitle(Loc.wordDetails.localized)
    }
}
```

## Adding New Strings

1. Add the key to the `Loc` enum in `Loc.swift`:
   ```swift
   static let newStringKey = "new_string_key"
   ```

2. Add the English translation to `en.lproj/Localizable.strings`:
   ```
   "new_string_key" = "New String";
   ```

3. Add the Russian translation to `ru.lproj/Localizable.strings`:
   ```
   "new_string_key" = "Новая строка";
   ```

## Key Naming Convention

- Use snake_case for keys
- Group related keys with descriptive prefixes
- Use descriptive names that indicate the context

Examples:
- `words` - Tab bar item
- `word_details` - Navigation title
- `add_word` - Button action
- `no_words_yet` - Empty state message

## Benefits

1. **Centralized Management**: All strings are in one place
2. **Type Safety**: Compile-time checking of string keys
3. **Easy Translation**: Clear structure for adding new languages
4. **Consistency**: Ensures consistent terminology across the app
5. **Maintainability**: Easy to update and modify strings

## Migration Guide

To migrate existing hardcoded strings:

1. Find all hardcoded strings in your views
2. Add corresponding keys to the `Loc` enum
3. Add translations to both `.strings` files
4. Replace hardcoded strings with `String.localized(Loc.key)`

## Supported Languages

Currently supported:
- English (en)
- Russian (ru)

To add a new language:
1. Create a new `.lproj` directory (e.g., `fr.lproj` for French)
2. Copy the `Localizable.strings` file from `en.lproj`
3. Translate all the strings to the target language
