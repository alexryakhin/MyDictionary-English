# MyDictionary-English iOS - Word Management Flow

## Table of Contents
1. [Flow Overview](#flow-overview)
2. [Screen-by-Screen Breakdown](#screen-by-screen-breakdown)
3. [Data Models & State Management](#data-models--state-management)
4. [Navigation & User Interactions](#navigation--user-interactions)
5. [Service Integration](#service-integration)
6. [Error Handling & Edge Cases](#error-handling--edge-cases)
7. [Implementation Guidelines](#implementation-guidelines)

---

## Flow Overview

### Primary User Journey
The Word Management Flow is the core functionality of the app, allowing users to create, organize, and manage their personal vocabulary. The journey begins at the Words tab and flows through various screens for adding, editing, and organizing words.

### Flow Diagram
```
Words Tab → Word List → Search/Filter → Add Word → Word Details → Edit/Manage → Shared Dictionaries
```

### Key User Goals
- **Add new words** with definitions, examples, and tags
- **Organize vocabulary** through search, filtering, and tagging
- **Edit existing words** to update definitions or add examples
- **Share words** with others through collaborative dictionaries
- **Track progress** through difficulty levels and quiz performance

---

## Screen-by-Screen Breakdown

### 1. Words Tab (Main Entry Point)

**File**: `WordsFlow.swift`
**Purpose**: Main entry point that wraps the word list view and handles navigation to other screens

**UI Components**:
- Tab button with "textformat" icon and "Words" label
- Flow container that manages the WordListView
- Navigation manager integration for handling screen transitions

**User Interactions**:
- Tab selection switches to the Words tab
- Navigation output handling routes to appropriate screens
- State restoration maintains tab selection across app sessions

**Implementation Details**:
The WordsFlow struct acts as a coordinator, receiving navigation events from the WordListViewModel and routing them through the NavigationManager to the appropriate destinations. It maintains a clean separation between the view logic and navigation logic.

### 2. Word List View

**File**: `WordListView.swift`
**Purpose**: Display and manage the user's collection of words with search, filtering, and sorting capabilities

**UI Components**:
- **Navigation Header**: Custom navigation with large title, search functionality, and add button
- **Search Bar**: Real-time search that filters words as the user types
- **Filter Controls**: Dropdown or segmented control for filtering by tags, difficulty, or date
- **Word List**: LazyVStack displaying word cells with swipe actions
- **Empty State**: Instructional view when no words exist, with prominent add button
- **Loading State**: Shimmer loading animation while data loads
- **Floating Action Button**: Quick access to add new words

**User Interactions**:
- **Search**: Real-time filtering updates the list as the user types
- **Filter**: Filter words by tags, difficulty level, or date added
- **Sort**: Sort words by date added, alphabetical order, or difficulty level
- **Add Word**: Navigate to the add word screen
- **Word Selection**: Tap a word to view its details
- **Swipe Actions**: Swipe left on words to reveal delete, edit, and share options
- **Pull to Refresh**: Pull down to refresh the word list

**State Management**:
The view uses WordListViewModel to manage the word data, search state, filter selections, and loading states. It observes changes to the Core Data context and updates the UI accordingly.

### 3. Add Word View

**File**: `AddWordContentView.swift`
**Purpose**: Create new words with manual entry or automatic definition lookup from external APIs

**UI Components**:
- **Navigation Header**: Back button and save button (disabled until form is valid)
- **Word Input Section**: Text field for entering the word with focus management
- **API Lookup Section**: Displays definitions from Wordnik API when a word is entered
- **Definition Input Section**: Manual definition entry with multi-line support
- **Part of Speech Section**: Dropdown selection for noun, verb, adjective, etc.
- **Phonetic Input Section**: Text field for pronunciation
- **Examples Section**: Dynamic list for adding multiple usage examples
- **Tag Selection Section**: Interface for choosing or creating tags
- **Language Selection Section**: Dropdown for choosing word language

**User Interactions**:
- **Word Entry**: Type a word to trigger automatic API definition lookup
- **Definition Selection**: Choose from API results or enter definition manually
- **Part of Speech**: Select from predefined options (noun, verb, adjective, adverb, etc.)
- **Phonetic Entry**: Add pronunciation using IPA or simplified phonetic notation
- **Example Addition**: Add multiple usage examples with add/remove functionality
- **Tag Management**: Select existing tags or create new ones with color selection
- **Save**: Validate form and save word to Core Data
- **Cancel**: Discard changes and return to word list

**State Management**:
The AddWordViewModel manages form validation, API calls, and Core Data operations. It tracks the form state and enables/disables the save button based on validation rules.

### 4. Word Details View

**File**: `WordDetailsContentView.swift`
**Purpose**: View and edit comprehensive word information with inline editing capabilities

**UI Components**:
- **Navigation Header**: Word title, back button, delete button, and listen button
- **Word Header**: Large title display of the word with pronunciation
- **Definition Section**: Editable definition with inline editing
- **Part of Speech Section**: Display and edit part of speech
- **Examples Section**: List of examples with add, edit, and delete functionality
- **Tags Section**: Display current tags with management interface
- **Difficulty Section**: Show current difficulty level and quiz performance
- **Language Section**: Display word language with edit capability
- **Action Buttons**: Delete, share, and other contextual actions

**User Interactions**:
- **Edit Definition**: Tap definition to enter edit mode with keyboard focus
- **Edit Phonetics**: Tap pronunciation to edit phonetic notation
- **Add Examples**: Add new usage examples with text input
- **Edit Examples**: Tap existing examples to modify them
- **Delete Examples**: Swipe or tap to remove examples
- **Manage Tags**: Add, remove, or create new tags
- **Delete Word**: Remove word from dictionary with confirmation
- **Share Word**: Share to shared dictionaries or export
- **Listen**: Text-to-speech pronunciation of the word

**State Management**:
The view directly observes the CDWord object and manages local editing state. Changes are saved back to Core Data when editing is complete.

### 5. Tag Selection View

**File**: `WordTagSelectionView.swift`
**Purpose**: Select and manage tags for organizing words with visual tag management

**UI Components**:
- **Navigation Header**: Back button and save button
- **Selected Tags Section**: Visual display of currently selected tags
- **Available Tags Section**: List of all available tags with selection toggles
- **Create Tag Section**: Interface for creating new tags with name and color
- **Tag Colors**: Color picker for new tag creation
- **Search**: Search functionality to filter through existing tags

**User Interactions**:
- **Tag Selection**: Toggle tags on/off to select or deselect them
- **Create Tag**: Add new tag with custom name and color selection
- **Search Tags**: Filter the tag list by typing in search field
- **Save Selection**: Apply selected tags to the word
- **Cancel**: Discard changes and return to previous screen

**State Management**:
The WordTagSelectionViewModel manages the tag selection state, search functionality, and tag creation. It maintains the current selection and handles the save operation.

### 6. Shared Dictionaries View

**File**: `SharedDictionariesListView.swift`
**Purpose**: Manage collaborative dictionaries and real-time word sharing

**UI Components**:
- **Navigation Header**: Title and add dictionary button
- **Dictionary List**: List of user's shared dictionaries with statistics
- **Dictionary Cards**: Visual cards showing dictionary info, word count, and collaborators
- **Collaborator List**: Display of dictionary collaborators with roles
- **Add Dictionary**: Interface for creating new shared dictionaries
- **Join Dictionary**: Functionality to join existing dictionaries via invitation

**User Interactions**:
- **View Dictionary**: Navigate to dictionary details and word list
- **Add Dictionary**: Create new shared dictionary with name and settings
- **Join Dictionary**: Join existing dictionary using invitation code
- **Manage Collaborators**: Add or remove collaborators with permission management
- **Delete Dictionary**: Remove shared dictionary (owner only)
- **Sync Status**: View real-time sync status and resolve conflicts

**State Management**:
The SharedDictionariesListViewModel manages the list of shared dictionaries, handles real-time updates from Firebase, and manages collaboration permissions.

---

## Data Models & State Management

### Core Data Models

**CDWord Entity**: The primary data model representing a word in the user's vocabulary. Contains fields for the word itself, definition, part of speech, phonetic pronunciation, examples array, language code, difficulty score, creation/update timestamps, sync status, and relationships to tags and quiz sessions.

**CDTag Entity**: Represents user-created tags for organizing words. Contains tag name, color selection, creation timestamp, and relationship to tagged words.

**CDQuizSession Entity**: Tracks quiz performance for individual words, storing scores, accuracy, and difficulty adjustments.

### View Models

**WordListViewModel**: Manages the word list display, search functionality, filtering, sorting, and navigation to other screens. Handles Core Data operations and maintains the filtered word list based on user interactions.

**AddWordViewModel**: Manages the word creation process, form validation, API integration for definition lookup, and Core Data persistence. Handles the complex state of the add word form including validation rules and API responses.

**WordDetailsViewModel**: Manages the word editing interface, inline editing capabilities, and real-time updates to the word data. Handles the transition between view and edit modes.

**WordTagSelectionViewModel**: Manages tag selection state, search functionality, and tag creation. Handles the relationship between words and tags in Core Data.

**SharedDictionariesListViewModel**: Manages shared dictionary data, real-time collaboration, and permission handling. Integrates with Firebase for real-time updates and conflict resolution.

---

## Navigation & User Interactions

### Navigation Flow
The navigation follows a hierarchical structure starting from the Words tab, with modal presentations for add/edit operations and push navigation for detail views. The NavigationManager handles deep linking and state restoration.

### User Interaction Patterns

**Search & Filter**: Real-time search updates the word list as the user types, with additional filtering by tags, difficulty, or date. Sort options allow organizing by various criteria.

**Swipe Actions**: Words in the list support swipe actions for quick access to delete, edit, and share functions, providing efficient interaction patterns.

**Pull to Refresh**: The word list supports pull-to-refresh for manual data synchronization and updates.

**Inline Editing**: Word details support inline editing for quick modifications without navigating to separate edit screens.

**Modal Presentations**: Add and edit operations use modal presentations to maintain context and provide clear entry/exit points.

---

## Service Integration

### Core Data Service
The Core Data Service manages local persistence with automatic CloudKit synchronization. It provides CRUD operations for all entities and handles background processing for data operations.

### Wordnik API Service
Integrates with the Wordnik API to provide automatic definition lookup when adding new words. Handles API rate limiting, error responses, and data parsing.

### Tag Service
Manages tag creation, retrieval, and relationship management. Handles tag color assignments and ensures data consistency.

### Dictionary Service
Manages shared dictionary functionality, real-time collaboration, and conflict resolution through Firebase Firestore integration.

### Analytics Service
Tracks user interactions, word creation patterns, and quiz performance for insights and progress tracking.

---

## Error Handling & Edge Cases

### Common Error Scenarios

**Network Errors**: Handle API failures, timeouts, and connectivity issues with user-friendly error messages and retry mechanisms.

**Validation Errors**: Form validation ensures data integrity with clear feedback for required fields and format requirements.

**Core Data Errors**: Handle database errors, migration issues, and sync conflicts with appropriate error recovery.

**API Rate Limiting**: Manage API usage limits and provide fallback options when external services are unavailable.

### Edge Cases

**Empty States**: Provide helpful guidance when no words exist, with clear calls-to-action to add the first word.

**Loading States**: Show appropriate loading indicators during data operations and API calls.

**Offline Mode**: Gracefully handle offline scenarios with cached data and sync when connectivity returns.

**Large Datasets**: Optimize performance for users with large word collections through pagination and efficient queries.

**Sync Conflicts**: Handle conflicts in shared dictionaries with clear resolution options and user choice.

---

## Implementation Guidelines

### SwiftUI Best Practices

**Property Wrappers**: Use appropriate property wrappers for state management - @StateObject for view models, @ObservedObject for external dependencies, @State for local view state, and @FocusState for text field management.

**View Composition**: Break down complex views into smaller, reusable components for better maintainability and testing.

**Custom Navigation**: Use consistent navigation patterns with custom modifiers for header styling and button placement.

### Performance Optimization

**Lazy Loading**: Use LazyVStack for large lists to improve scrolling performance and memory usage.

**Background Processing**: Perform heavy operations on background queues to maintain UI responsiveness.

**Memory Management**: Properly manage Combine cancellables and Core Data contexts to prevent memory leaks.

### Accessibility

**VoiceOver Support**: Provide comprehensive accessibility labels, hints, and values for all interactive elements.

**Dynamic Type**: Support system font scaling for users with accessibility needs.

**Color Contrast**: Ensure proper color contrast ratios for text and interactive elements.

### Testing Considerations

**Unit Tests**: Test view models, services, and data operations with comprehensive test coverage.

**UI Tests**: Test user flows and interactions to ensure proper functionality across different scenarios.

**Integration Tests**: Test the integration between different services and data flows.

---

This Word Management Flow document provides comprehensive implementation details for the core word management functionality in the MyDictionary iOS app, covering all screens, interactions, data flow, and implementation patterns needed for accurate development.
