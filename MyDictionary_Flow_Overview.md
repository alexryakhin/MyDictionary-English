# MyDictionary-English App - iOS Flow Overview Document

## Table of Contents
1. [iOS App Architecture Overview](#ios-app-architecture-overview)
2. [iOS Navigation Structure](#ios-navigation-structure)
3. [Core iOS User Flows](#core-ios-user-flows)
4. [iOS Data Flow Patterns](#ios-data-flow-patterns)
5. [iOS Service Layer Architecture](#ios-service-layer-architecture)
6. [iOS Implementation Guidelines](#ios-implementation-guidelines)

---

## iOS App Architecture Overview

### iOS Navigation Structure
- **Primary Navigation**: TabView with 5 main tabs
- **Secondary Navigation**: NavigationStack with NavigationDestination enum
- **Modal Presentation**: Sheets for add/edit operations
- **Deep Linking**: NavigationManager handles programmatic navigation

### Core iOS Architecture Components

#### State Management
- **MVVM Pattern**: @StateObject/@ObservedObject for view models
- **Combine Framework**: Reactive programming with publishers
- **Shared Services**: Singleton pattern for cross-view consistency

#### Data Persistence
- **Core Data**: Local data persistence with CloudKit sync
- **Firebase Firestore**: Real-time collaboration and cloud sync
- **UserDefaults**: App settings and preferences

---

## iOS Navigation Structure

### Tab Navigation

| Tab | Icon | Purpose | Primary Flow | View Model |
|-----|------|---------|--------------|------------|
| **Words** | `textformat` | Word management | WordsFlow | WordListViewModel |
| **Idioms** | `quote.bubble` | Idiom management | IdiomsFlow | IdiomListViewModel |
| **Quizzes** | `brain.head.profile` | Quiz practice | QuizzesFlow | QuizzesListViewModel |
| **Progress** | `chart.line.uptrend.xyaxis` | Analytics | AnalyticsFlow | AnalyticsViewModel |
| **Settings** | `gearshape` | App configuration | SettingsFlow | SettingsViewModel |

### Navigation Destinations (iOS)

```swift
enum NavigationDestination: Hashable {
    // Word Management
    case addWord
    case wordDetails(CDWord)
    case addExistingWordToShared(CDWord)
    
    // Shared Dictionaries
    case sharedWordDetails(SharedWord, dictionaryId: String)
    case sharedWordDifficultyStats(word: SharedWord)
    case addSharedDictionary
    case sharedDictionaryWords(SharedDictionary)
    case sharedDictionaryDetails(SharedDictionary)
    case sharedDictionariesList
    
    // Idiom Management
    case addIdiom
    case idiomDetails(CDIdiom)
    
    // Quiz System
    case spellingQuiz(wordCount: Int, hardWordsOnly: Bool)
    case chooseDefinitionQuiz(wordCount: Int, hardWordsOnly: Bool)
    case quizResultsDetail
    
    // Settings & Configuration
    case aboutApp
    case tagManagement
    case authentication
}
```


### iOS Navigation Implementation

```swift
// Main Tab View Structure
TabView(selection: $tabManager.selectedTab) {
    WordsFlow(viewModel: wordsViewModel)
        .tabItem { 
            Image(systemName: "textformat")
            Text("Words")
        }
        .tag(TabBarItem.words)
    
    IdiomsFlow(viewModel: idiomsViewModel)
        .tabItem { 
            Image(systemName: "quote.bubble")
            Text("Idioms")
        }
        .tag(TabBarItem.idioms)
    
    // ... other tabs
}

// Navigation Stack Implementation
NavigationStack(path: $navigationManager.navigationPath) {
    // Content
}
.navigationDestination(for: NavigationDestination.self) { destination in
    destinationView(for: destination)
}
```

---

## Core iOS User Flows

### 1. App Initialization Flow

```
App Launch
├── Onboarding (First Launch)
│   ├── Welcome Screen
│   ├── Feature Introduction
│   └── Continue to Main App
├── Authentication Check
│   ├── Signed In → Load User Data
│   └── Not Signed In → Guest Mode
├── Data Sync
│   ├── Local Data Load
│   ├── Cloud Sync (if authenticated)
│   └── Shared Dictionary Listeners
└── Main Tab View
    ├── Words Tab (Default)
    ├── Tab State Restoration
    └── Navigation State Restoration
```

### 2. Word Management Flow

```
Words Tab
├── Word List View
│   ├── Search & Filter
│   ├── Sort Options
│   ├── Tag Filtering
│   └── Empty State
├── Add Word
│   ├── Manual Entry
│   ├── API Definition Lookup
│   ├── Tag Selection
│   └── Save to Core Data
├── Word Details
│   ├── Edit Word
│   ├── Add Examples
│   ├── Manage Tags
│   ├── Delete Word
│   └── Share to Dictionary
└── Shared Dictionaries
    ├── Add to Shared
    ├── View Shared Words
    ├── Difficulty Stats
    └── Collaboration
```

### 3. Quiz Practice Flow

```
Quizzes Tab
├── Quiz Selection
│   ├── Spelling Quiz
│   ├── Choose Definition Quiz
│   └── Quiz Settings
├── Quiz Configuration
│   ├── Word Count Selection
│   ├── Difficulty Filter
│   ├── Tag Filtering
│   └── Start Quiz
├── Quiz Session
│   ├── Question Display
│   ├── Answer Input
│   ├── Progress Tracking
│   ├── Hint System
│   └── Skip Option
├── Quiz Results
│   ├── Score Display
│   ├── Performance Analysis
│   ├── Word Difficulty Updates
│   └── Progress Tracking
└── Analytics Update
    ├── Session Recording
    ├── Statistics Update
    └── Streak Tracking
```

### 4. Progress Analytics Flow

```
Progress Tab
├── Analytics Overview
│   ├── Progress Summary
│   ├── Time Period Selection
│   ├── Growth Charts
│   └── Performance Metrics
├── Quiz Results Detail
│   ├── Recent Sessions
│   ├── Performance Breakdown
│   ├── Word Difficulty Analysis
│   └── Export Options
├── Statistics
│   ├── Total Words
│   ├── Mastered Words
│   ├── Quiz Accuracy
│   └── Study Streaks
└── Data Export
    ├── CSV Export
    ├── Progress Reports
    └── Share Analytics
```

### 5. Settings & Configuration Flow

```
Settings Tab
├── User Profile
│   ├── Authentication
│   ├── Account Management
│   └── Sync Status
├── App Configuration
│   ├── Notification Settings
│   ├── Language Preferences
│   ├── Theme Selection
│   └── Privacy Settings
├── Data Management
│   ├── Import/Export
│   ├── Backup/Restore
│   ├── Data Sync
│   └── Clear Data
├── Tag Management
│   ├── Create Tags
│   ├── Edit Tags
│   ├── Delete Tags
│   └── Tag Colors
└── About & Support
    ├── App Information
    ├── Version Details
    ├── Support Contact
    └── Legal Information
```

### 6. Shared Dictionary Flow

```
Shared Dictionaries
├── Dictionary List
│   ├── My Dictionaries
│   ├── Shared with Me
│   ├── Create Dictionary
│   └── Join Dictionary
├── Dictionary Management
│   ├── Add Collaborators
│   ├── Manage Permissions
│   ├── Dictionary Settings
│   └── Delete Dictionary
├── Word Collaboration
│   ├── Add Words
│   ├── Edit Words
│   ├── Difficulty Ratings
│   ├── Like System
│   └── Comments
└── Real-time Updates
    ├── Live Collaboration
    ├── Conflict Resolution
    ├── Offline Sync
    └── Notification System
```

---

## iOS Data Flow Patterns

### 1. Local Data Flow

```
User Action → View → ViewModel → Service → Core Data/Room
     ↑                                                    ↓
     └── UI Update ← State Update ← Data Change ←───────┘
```

### 2. Cloud Sync Flow

```
Local Change → Service → Firestore → Other Devices
     ↑                                    ↓
     └── UI Update ← State Update ←───┘
```

### 3. Real-time Collaboration Flow

```
User Action → Service → Firestore → Real-time Listener → Other Users
     ↑                                                          ↓
     └── UI Update ← State Update ←───┘
```

### 4. Quiz Data Flow

```
Quiz Start → Word Provider → Quiz Session → Analytics Service → Core Data
     ↑                                                              ↓
     └── UI Update ← Progress Update ←───┘
```

---

## iOS Service Layer Architecture

### Core Services

#### 1. AuthenticationService
- **Purpose**: User authentication and account management
- **Platforms**: iOS, macOS, Android
- **Features**: 
  - Google/Apple Sign-In
  - Anonymous authentication
  - Account linking
  - User profile management

#### 2. CoreDataService
- **Purpose**: Local data persistence using Core Data
- **Features**:
  - CRUD operations for all entities
  - Data relationships and constraints
  - Migration handling
  - Background processing with NSManagedObjectContext

#### 3. DictionaryService
- **Purpose**: Shared dictionary management
- **Features**:
  - Real-time collaboration
  - Conflict resolution
  - Offline sync
  - Permission management

#### 4. AnalyticsService
- **Purpose**: Usage tracking and analytics
- **Features**:
  - Event logging
  - Performance metrics
  - User behavior tracking
  - Progress analytics

#### 5. QuizAnalyticsService
- **Purpose**: Quiz-specific analytics
- **Features**:
  - Session recording
  - Performance tracking
  - Difficulty adjustment
  - Progress calculation

#### 6. NotificationService
- **Purpose**: Push notifications and reminders
- **Features**:
  - Study reminders
  - Achievement notifications
  - Collaboration updates
  - Custom scheduling

### Data Models

#### Core Entities
- **CDWord/Word**: Word data with definitions, examples, tags
- **CDIdiom/Idiom**: Idiom data with meanings and usage
- **CDTag/Tag**: Tagging system for organization
- **CDQuizSession/QuizSession**: Quiz performance tracking
- **SharedWord**: Collaborative word data
- **SharedDictionary**: Collaborative dictionary data

#### Supporting Models
- **Difficulty**: Learning difficulty levels (New, In Progress, Needs Review, Mastered)
- **FilterCase**: Data filtering options
- **SortingCase**: Data sorting options
- **AnalyticsEvent**: Analytics event tracking

---

## iOS Implementation Guidelines

### iOS Implementation Patterns

#### Navigation
```swift
// Tab Navigation
TabView(selection: $selectedTab) {
    WordsFlow()
        .tabItem { ... }
    IdiomsFlow()
        .tabItem { ... }
    // ... other tabs
}

// Stack Navigation
NavigationStack(path: $navigationPath) {
    // Content
}
.navigationDestination(for: NavigationDestination.self) { destination in
    destinationView(for: destination)
}
```

#### State Management
```swift
@StateObject private var viewModel: WordListViewModel
@ObservedObject var service: DictionaryService = .shared

// Output handling
.onReceive(viewModel.output) { output in
    handleOutput(output)
}
```

#### View Model Pattern
```swift
final class WordListViewModel: BaseViewModel {
    enum Output {
        case showWordDetails(CDWord)
        case showAddWord
        case showSharedDictionaries
    }
    
    var output = PassthroughSubject<Output, Never>()
    
    @Published private(set) var words: [CDWord] = []
    @Published private(set) var isLoading = false
    
    // Implementation...
}
```

#### Service Integration
```swift
// Service singleton pattern
class DictionaryService: ObservableObject {
    static let shared = DictionaryService()
    private init() {}
    
    @Published var sharedWords: [SharedWord] = []
    
    func getDifficultyStats(for wordId: String, in dictionaryId: String) async throws -> [String: Int] {
        // Implementation...
    }
}
```

### iOS-Specific Implementation Guidelines

#### 1. SwiftUI Best Practices
- Use `@StateObject` for view models that own data
- Use `@ObservedObject` for external dependencies
- Use `@State` for local view state
- Use `@Environment` for system values

#### 2. Navigation Patterns
- Use `NavigationStack` for iOS 16+ navigation
- Implement custom navigation modifiers for consistent headers
- Use sheets for modal presentations
- Handle deep linking with NavigationManager

#### 3. Data Management
- Use Core Data for local persistence
- Implement proper error handling with async/await
- Use Combine for reactive data updates
- Handle background processing with Task

#### 4. UI/UX Guidelines
- Follow iOS Human Interface Guidelines
- Use SF Symbols for consistent iconography
- Implement proper accessibility support
- Use haptic feedback for user interactions

---

## iOS Implementation Priority

### Phase 1: Core iOS Functionality
1. **Word Management** - Basic CRUD operations with Core Data
2. **Navigation System** - TabView and NavigationStack implementation
3. **Basic Quizzes** - Spelling and definition quiz functionality
4. **Local Data Persistence** - Core Data setup and management

### Phase 2: Advanced iOS Features
1. **Authentication** - Firebase Auth integration
2. **Analytics** - Progress tracking and statistics
3. **Shared Dictionaries** - Firebase Firestore collaboration
4. **Advanced UI Components** - Custom navigation and section views

### Phase 3: iOS Polish & Optimization
1. **Performance Optimization** - Core Data optimization and UI responsiveness
2. **Advanced Analytics** - Detailed insights and reporting
3. **Real-time Features** - Live collaboration and updates
4. **iOS-specific Features** - Haptic feedback, accessibility, and native integration

---

This iOS Flow Overview Document provides the foundation for implementing MyDictionary-English on iOS. Each subsequent document will dive deeper into specific iOS flows and implementation details.
