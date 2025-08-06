# MyDictionary-English App - Complete Screen Documentation

## Table of Contents
1. [App Overview](#app-overview)
2. [Navigation Structure](#navigation-structure)
3. [iOS Screens](#ios-screens)
4. [macOS Screens](#macos-screens)
5. [Shared Components](#shared-components)
6. [User Flows](#user-flows)

## App Overview

MyDictionary-English is a comprehensive vocabulary learning application available on both iOS and macOS platforms. The app allows users to create personal word lists, practice with quizzes, track progress, and manage their vocabulary learning journey.

### Key Features
- **Word Management**: Add, edit, and organize words with definitions, examples, and tags
- **Idiom Management**: Create and manage idiom collections
- **Interactive Quizzes**: Spelling and definition-based quizzes
- **Progress Analytics**: Track learning progress and performance
- **Cross-platform Sync**: Sync data across devices via authentication
- **Import/Export**: CSV import/export functionality

## Navigation Structure

### iOS Navigation
The iOS app uses a **TabView** with 5 main tabs:
1. **Words** - Main word management
2. **Idioms** - Idiom management
3. **Quizzes** - Quiz selection and practice
4. **Progress** - Analytics and progress tracking
5. **Settings** - App configuration and user preferences

### macOS Navigation
The macOS app uses a **NavigationSplitView** with a sidebar containing:
1. **Words** - Word management
2. **Idioms** - Idiom management
3. **Quizzes** - Quiz selection
4. **Progress** - Analytics
5. **Settings** - App configuration

## iOS Screens

### 1. Onboarding Screen
**File**: `OnboardingView.swift`
**Purpose**: Welcome new users and introduce app features
**Features**:
- Welcome message with app title
- Three feature highlights:
  - Personal word list creation
  - Internet definitions lookup
  - Interactive quizzes
- Continue button to dismiss onboarding

### 2. Main Tab View
**File**: `MainTabView.swift`
**Purpose**: Main navigation container for the app
**Features**:
- Tab-based navigation with 5 main sections
- NavigationSplitView for Words and Idioms tabs
- NavigationView for Quizzes, Progress, and Settings tabs
- iPad-specific sidebar navigation support

### 3. Words Tab

#### 3.1 Word List Screen
**File**: `WordListContentView.swift`
**Purpose**: Display and manage user's word collection
**Features**:
- **Search functionality** with real-time filtering
- **Tag filtering** to organize words by categories
- **Sort options** (alphabetical, date added, etc.)
- **Context menu** for quick actions (delete)
- **Add word button** in navigation bar
- **Empty state** with encouraging messages
- **Word count display** in section footer
- **Quick add suggestion** when searching

#### 3.2 Add Word Screen
**File**: `AddWordContentView.swift`
**Purpose**: Create new word entries with comprehensive information
**Features**:
- **Word input field** with search functionality
- **Input language selection** (supports multiple languages)
- **Definition field** for manual entry
- **Part of speech selection** (noun, verb, adjective, etc.)
- **Pronunciation display** with audio playback
- **Tag selection** with visual tag chips
- **Definition selection** from API results
- **Translation support** for non-English locales
- **Examples display** from API definitions
- **Save functionality** with validation

#### 3.3 Word Details Screen
**File**: `WordDetailsContentView.swift`
**Purpose**: View and edit detailed word information
**Features**:
- **Transcription editing** with audio playback
- **Part of speech management** with context menu
- **Definition editing** with audio playback
- **Difficulty level management** with picker
- **Language display** with code indicators
- **Tag management** with add/remove functionality
- **Examples management** with add/edit/delete
- **Favorite toggle** with heart icon
- **Delete functionality** with confirmation
- **Audio playback** for word and definition

### 4. Idioms Tab

#### 4.1 Idiom List Screen
**File**: `IdiomListContentView.swift`
**Purpose**: Display and manage user's idiom collection
**Features**:
- **Search functionality** with real-time filtering
- **Sort and filter options** in menu
- **Context menu** for quick actions (delete)
- **Add idiom button** in navigation bar
- **Empty state** with encouraging messages
- **Quick add suggestion** when searching

#### 4.2 Add Idiom Screen
**File**: `AddIdiomContentView.swift`
**Purpose**: Create new idiom entries
**Features**:
- **Idiom input field**
- **Definition field**
- **Meaning field**
- **Example usage field**
- **Save functionality**

#### 4.3 Idiom Details Screen
**File**: `IdiomDetailsContentView.swift`
**Purpose**: View and edit detailed idiom information
**Features**:
- **Idiom text display**
- **Definition editing**
- **Meaning editing**
- **Example editing**
- **Favorite toggle**
- **Delete functionality**

### 5. Quizzes Tab

#### 5.1 Quiz List Screen
**File**: `QuizzesListContentView.swift`
**Purpose**: Select and configure quiz sessions
**Features**:
- **Practice settings section**:
  - Hard words only toggle
  - Words per session slider (1-50)
  - Dynamic range based on available words
- **Quiz types**:
  - Spelling Quiz
  - Choose Definition Quiz
- **Insufficient words placeholder** (requires 10+ words)
- **Insufficient hard words placeholder** (for hard words mode)
- **Navigation to individual quiz types**

#### 5.2 Spelling Quiz Screen
**File**: `SpellingQuizContentView.swift`
**Purpose**: Practice spelling words based on definitions
**Features**:
- **Progress tracking** with visual progress bar
- **Score display** with current and best scores
- **Streak tracking** with fire emoji
- **Definition card** with part of speech
- **Hint system** showing first letter
- **Answer input field** with validation
- **Attempt tracking** (up to 3 attempts)
- **Correct/incorrect feedback**
- **Skip option** with point penalty
- **Completion screen** with results summary
- **Error handling** for insufficient words

#### 5.3 Choose Definition Quiz Screen
**File**: `ChooseDefinitionQuizContentView.swift`
**Purpose**: Practice selecting correct definitions for words
**Features**:
- **Word display** with audio playback
- **Multiple choice definitions**
- **Progress tracking**
- **Score calculation**
- **Completion screen**

### 6. Progress Tab

#### 6.1 Analytics Screen
**File**: `AnalyticsContentView.swift`
**Purpose**: Display learning progress and performance metrics
**Features**:
- **Progress overview cards**:
  - In Progress words count
  - Mastered words count
  - Need Review words count
- **Statistics cards**:
  - Practice time
  - Accuracy percentage
  - Total sessions
- **Recent quiz results** with navigation to details
- **Vocabulary growth chart** with time period selection
- **Empty states** for no data
- **Pull-to-refresh** functionality

#### 6.2 Quiz Results Detail Screen
**File**: `QuizResultsDetailView.swift`
**Purpose**: Detailed view of quiz session history
**Features**:
- **Quiz session list** with dates and scores
- **Detailed statistics** per session
- **Performance trends**

### 7. Settings Tab

#### 7.1 Settings Screen
**File**: `SettingsContentView.swift`
**Purpose**: Configure app preferences and manage data
**Features**:
- **Translation settings** (for non-English locales)
- **Notification preferences**:
  - Daily reminders
  - Difficult words reminders
- **Authentication section**:
  - Sign in status display
  - Sign in/sign out functionality
  - Account linking options
- **Tag management** navigation
- **Import/Export functionality**:
  - CSV import
  - CSV export
- **About app** navigation
- **File picker** for CSV import

#### 7.2 Authentication Screen
**File**: `AuthenticationView.swift`
**Purpose**: User authentication and account management
**Features**:
- **Google Sign-In** integration
- **Apple Sign-In** integration
- **Account linking** for multiple providers
- **Loading states** during authentication
- **Skip option** for local-only mode
- **Error handling** for authentication failures

#### 7.3 Tag Management Screen
**File**: `TagManagementView.swift`
**Purpose**: Create and manage word tags
**Features**:
- **Tag list** with color indicators
- **Add tag** functionality
- **Edit tag** functionality
- **Delete tag** functionality
- **Color selection** for tags

#### 7.4 About App Screen
**File**: `AboutAppContentView.swift`
**Purpose**: Display app information and version details
**Features**:
- **App version** information
- **Developer information**
- **App description**
- **Contact information**

## macOS Screens

### 1. Main Tab View (macOS)
**File**: `MainTabView.swift` (macOS)
**Purpose**: macOS-specific navigation with sidebar
**Features**:
- **Sidebar navigation** with icons and labels
- **Content area** for list views
- **Detail area** for selected items
- **Settings button** in sidebar footer
- **Responsive layout** for different window sizes

### 2. Words Management (macOS)

#### 2.1 Word List View
**File**: `WordsListView.swift`
**Purpose**: macOS-optimized word list display
**Features**:
- **Table view** with columns
- **Search functionality**
- **Sort options**
- **Selection handling**

#### 2.2 Word Details View
**File**: `WordDetailsView.swift`
**Purpose**: macOS-optimized word details display
**Features**:
- **Form-based layout**
- **Inline editing**
- **Sidebar integration**

### 3. Idioms Management (macOS)

#### 3.1 Idiom List View
**File**: `IdiomsListView.swift`
**Purpose**: macOS-optimized idiom list display
**Features**:
- **Table view** with columns
- **Search functionality**
- **Sort options**

#### 3.2 Idiom Details View
**File**: `IdiomDetailsView.swift`
**Purpose**: macOS-optimized idiom details display
**Features**:
- **Form-based layout**
- **Inline editing**

### 4. Quizzes (macOS)

#### 4.1 Quizzes View
**File**: `QuizzesView.swift`
**Purpose**: macOS-optimized quiz selection
**Features**:
- **Quiz type selection**
- **Settings configuration**
- **Navigation to quiz types**

#### 4.2 Spelling Quiz View
**File**: `SpellingQuizView.swift`
**Purpose**: macOS-optimized spelling quiz
**Features**:
- **Keyboard shortcuts**
- **Window-optimized layout**
- **Progress tracking**

#### 4.3 Choose Definition View
**File**: `ChooseDefinitionView.swift`
**Purpose**: macOS-optimized definition quiz
**Features**:
- **Multiple choice interface**
- **Keyboard navigation**

### 5. Progress Analytics (macOS)

#### 5.1 Progress Analytics View
**File**: `ProgressAnalyticsView.swift`
**Purpose**: macOS-optimized analytics display
**Features**:
- **Chart visualizations**
- **Statistics panels**
- **Data export options**

### 6. Settings (macOS)

#### 6.1 Settings View
**File**: `SettingsView.swift`
**Purpose**: macOS-optimized settings interface
**Features**:
- **Form-based layout**
- **System integration**
- **Preference management**

## Shared Components

### 1. Core User Interface Components
**Location**: `CoreUserInterface/`
**Components**:
- **CustomSectionView**: Reusable section containers
- **CellWrapper**: Standardized cell layouts
- **ShimmerView**: Loading state animations
- **CustomAlertView**: Custom alert implementations
- **HapticManager**: Haptic feedback management

### 2. Extensions
**Location**: `Extensions/`
**Components**:
- **View extensions**: Common view modifiers
- **Array extensions**: Collection utilities
- **Bundle extensions**: App information utilities
- **NotificationCenter extensions**: Event handling

### 3. Models
**Location**: `Models/`
**Components**:
- **AlertModel**: Alert configuration
- **Difficulty**: Learning difficulty levels
- **FilterCase**: Filtering options
- **SortingCase**: Sorting options

## User Flows

### 1. New User Onboarding Flow
1. **App Launch** → Onboarding Screen
2. **Feature Introduction** → Continue Button
3. **Main App** → Words Tab (empty state)
4. **Add First Word** → Add Word Screen
5. **Word Creation** → Word Details Screen

### 2. Word Management Flow
1. **Words Tab** → Word List Screen
2. **Search/Filter** → Filtered Results
3. **Add Word** → Add Word Screen
4. **API Definition Selection** → Word Creation
5. **Word Details** → Edit/Manage Word
6. **Tag Management** → Tag Selection Screen

### 3. Quiz Practice Flow
1. **Quizzes Tab** → Quiz List Screen
2. **Configure Settings** → Word Count/Difficulty
3. **Select Quiz Type** → Spelling/Definition Quiz
4. **Quiz Session** → Interactive Practice
5. **Results Screen** → Performance Summary
6. **Progress Update** → Analytics Screen

### 4. Progress Tracking Flow
1. **Progress Tab** → Analytics Screen
2. **View Statistics** → Progress Overview
3. **Recent Results** → Quiz Results Detail
4. **Growth Chart** → Time Period Selection
5. **Export Data** → Settings Screen

### 5. Settings Management Flow
1. **Settings Tab** → Settings Screen
2. **Authentication** → Sign In Screen
3. **Account Linking** → Provider Selection
4. **Tag Management** → Tag Management Screen
5. **Import/Export** → File Selection
6. **Notifications** → System Settings

### 6. Cross-Platform Sync Flow
1. **Settings** → Authentication Screen
2. **Sign In** → Google/Apple Authentication
3. **Account Linking** → Multiple Providers
4. **Data Sync** → Cloud Storage
5. **Device Sync** → Real-time Updates

## Technical Architecture

### Data Models
- **CDWord**: Core Data word entity
- **CDIdiom**: Core Data idiom entity
- **CDTag**: Core Data tag entity
- **CDQuizSession**: Core Data quiz session entity

### Services
- **CoreDataService**: Local data persistence
- **AuthenticationService**: User authentication
- **AnalyticsService**: Usage tracking
- **TTSService**: Text-to-speech functionality
- **WordnikAPIService**: External definition API

### View Models
- **WordListViewModel**: Word list management
- **AddWordViewModel**: Word creation logic
- **QuizViewModel**: Quiz session management
- **AnalyticsViewModel**: Progress tracking
- **SettingsViewModel**: App configuration

## Platform Differences

### iOS-Specific Features
- **TabView Navigation**: Bottom tab navigation
- **NavigationSplitView**: Master-detail for Words/Idioms
- **Haptic Feedback**: Touch-based interactions
- **Context Menus**: Long-press actions
- **Pull-to-Refresh**: Swipe gestures

### macOS-Specific Features
- **NavigationSplitView**: Sidebar navigation
- **Keyboard Shortcuts**: Keyboard-based interactions
- **Window Management**: Multi-window support
- **Menu Bar Integration**: System menu integration
- **Drag & Drop**: File import/export

This documentation provides a comprehensive overview of all screens, features, and user flows in the MyDictionary-English application across both iOS and macOS platforms. 