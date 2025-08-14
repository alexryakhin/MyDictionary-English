# MyDictionary-English iOS - Quiz Practice Flow

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
The Quiz Practice Flow is the core learning mechanism of the app, allowing users to test and improve their vocabulary knowledge through interactive quizzes. The journey begins at the Quizzes tab and flows through quiz selection, configuration, practice sessions, and results analysis.

### Flow Diagram
```
Quizzes Tab → Quiz Selection → Quiz Configuration → Quiz Session → Results → Progress Update
```

### Key User Goals
- **Practice vocabulary** through interactive quiz sessions
- **Track progress** and identify areas for improvement
- **Adapt difficulty** based on performance
- **Review results** to understand strengths and weaknesses
- **Build confidence** through regular practice

---

## Screen-by-Screen Breakdown

### 1. Quizzes Tab (Main Entry Point)

**File**: `QuizzesFlow.swift`
**Purpose**: Main entry point that wraps the quiz list view and handles navigation to quiz sessions

**UI Components**:
- Tab button with "brain.head.profile" icon and "Quizzes" label
- Flow container that manages the QuizzesListView
- Navigation manager integration for handling quiz session transitions

**User Interactions**:
- Tab selection switches to the Quizzes tab
- Navigation output handling routes to appropriate quiz types
- State restoration maintains tab selection across app sessions

**Implementation Details**:
The QuizzesFlow struct acts as a coordinator, receiving navigation events from the QuizzesListViewModel and routing them through the NavigationManager to the appropriate quiz sessions.

### 2. Quiz List View

**File**: `QuizzesListView.swift`
**Purpose**: Display available quiz types and allow users to configure and start quiz sessions

**UI Components**:
- **Navigation Header**: Custom navigation with large title and settings button
- **Quiz Type Cards**: Visual cards for each quiz type (Spelling, Choose Definition)
- **Quiz Configuration**: Settings for word count, difficulty filters, and tag selection
- **Quick Start Options**: Pre-configured quiz settings for quick access
- **Recent Results**: Display of recent quiz performance
- **Progress Indicators**: Visual feedback on learning progress
- **Empty State**: Guidance when no words are available for quizzes

**User Interactions**:
- **Quiz Selection**: Tap a quiz type to configure and start
- **Configuration**: Adjust word count, difficulty filters, and tag preferences
- **Quick Start**: Use pre-configured settings for immediate practice
- **View Results**: Access recent quiz results and performance analytics
- **Settings**: Configure quiz preferences and difficulty settings

**State Management**:
The view uses QuizzesListViewModel to manage quiz configuration, word availability, and navigation to quiz sessions.

### 3. Quiz Configuration View

**File**: `QuizConfigurationView.swift`
**Purpose**: Configure quiz settings before starting a practice session

**UI Components**:
- **Navigation Header**: Back button and start quiz button
- **Quiz Type Selection**: Choose between Spelling and Choose Definition quizzes
- **Word Count Slider**: Adjust number of words in the quiz session
- **Difficulty Filter**: Filter words by difficulty level (all, hard words only)
- **Tag Filter**: Select specific tags to include in the quiz
- **Preview Section**: Show sample words that will be included
- **Settings Summary**: Display current configuration settings

**User Interactions**:
- **Quiz Type**: Select between spelling and definition quizzes
- **Word Count**: Adjust the number of words (5-50 range)
- **Difficulty Filter**: Choose to include all words or only difficult ones
- **Tag Selection**: Filter words by specific tags
- **Start Quiz**: Begin the quiz session with current settings
- **Reset Settings**: Return to default configuration

**State Management**:
The QuizConfigurationViewModel manages the configuration state, validates settings, and prepares the word list for the quiz session.

### 4. Spelling Quiz View

**File**: `SpellingQuizContentView.swift`
**Purpose**: Interactive spelling quiz where users type the word based on definition and examples

**UI Components**:
- **Progress Header**: Quiz progress indicator and score display
- **Definition Card**: Clear display of word definition
- **Examples Section**: Usage examples to provide context
- **Answer Input**: Text field for user to type the word
- **Hint System**: Optional hints to help with difficult words
- **Action Buttons**: Submit answer, skip word, and next word buttons
- **Feedback Display**: Immediate feedback on correct/incorrect answers
- **Timer**: Optional time limit for each question

**User Interactions**:
- **Read Definition**: Review the word definition and examples
- **Type Answer**: Enter the word in the text field
- **Submit Answer**: Check if the answer is correct
- **Use Hints**: Access hints for difficult words
- **Skip Word**: Move to the next word without answering
- **View Feedback**: See immediate feedback on answer correctness
- **Continue**: Proceed to the next question

**State Management**:
The SpellingQuizViewModel manages the quiz session state, tracks user answers, calculates scores, and handles the progression through questions.

### 5. Choose Definition Quiz View

**File**: `ChooseDefinitionQuizContentView.swift`
**Purpose**: Multiple choice quiz where users select the correct definition for a given word

**UI Components**:
- **Progress Header**: Quiz progress indicator and score display
- **Word Display**: Clear presentation of the target word
- **Multiple Choice Options**: 4 definition options to choose from
- **Answer Selection**: Tap to select the correct definition
- **Feedback Display**: Immediate feedback on answer selection
- **Action Buttons**: Next question and skip buttons
- **Timer**: Optional time limit for each question
- **Difficulty Indicator**: Visual cue for word difficulty

**User Interactions**:
- **Read Word**: Review the target word and its context
- **Select Answer**: Tap one of the four definition options
- **View Feedback**: See immediate feedback on selection
- **Continue**: Proceed to the next question
- **Skip Question**: Move to the next word without answering
- **Review Options**: Re-read the definition choices

**State Management**:
The ChooseDefinitionQuizViewModel manages the multiple choice format, generates distractors, tracks user selections, and calculates performance metrics.

### 6. Quiz Results View

**File**: `QuizResultsContentView.swift`
**Purpose**: Display comprehensive results and performance analysis after quiz completion

**UI Components**:
- **Score Summary**: Overall score and performance metrics
- **Performance Chart**: Visual representation of quiz performance
- **Word-by-Word Results**: Detailed breakdown of each question
- **Difficulty Analysis**: Performance by difficulty level
- **Progress Update**: Changes in word difficulty levels
- **Action Buttons**: Retry quiz, view analytics, and return to list
- **Achievement Badges**: Recognition for good performance
- **Share Results**: Option to share performance with others

**User Interactions**:
- **Review Performance**: Examine overall score and accuracy
- **Analyze Results**: Review individual question performance
- **View Progress**: See how word difficulties have changed
- **Retry Quiz**: Start a new quiz with similar settings
- **View Analytics**: Access detailed performance analytics
- **Share Results**: Share performance with friends or social media
- **Return to List**: Go back to the quiz selection screen

**State Management**:
The QuizResultsViewModel processes the quiz session data, calculates performance metrics, updates word difficulties, and prepares the results for display.

### 7. Quiz Analytics View

**File**: `QuizAnalyticsContentView.swift`
**Purpose**: Detailed analytics and progress tracking for quiz performance over time

**UI Components**:
- **Performance Overview**: Summary of overall quiz performance
- **Progress Charts**: Visual charts showing improvement over time
- **Quiz History**: List of recent quiz sessions with results
- **Difficulty Trends**: Analysis of performance by difficulty level
- **Word Performance**: Individual word performance tracking
- **Streak Tracking**: Current and best performance streaks
- **Goal Setting**: Set and track learning goals
- **Export Options**: Export analytics data

**User Interactions**:
- **View Trends**: Analyze performance patterns over time
- **Review History**: Examine past quiz sessions
- **Track Progress**: Monitor improvement in specific areas
- **Set Goals**: Establish learning targets and milestones
- **Export Data**: Download analytics for external review
- **Filter Results**: View analytics for specific time periods

**State Management**:
The QuizAnalyticsViewModel aggregates quiz session data, calculates trends, and provides insights into learning progress.

---

## Data Models & State Management

### Core Data Models

**CDQuizSession Entity**: Tracks individual quiz sessions with metadata including quiz type, score, accuracy, duration, word count, and timestamp. Contains relationships to the words that were quizzed.

**CDWord Entity**: Enhanced with quiz-related fields including difficulty score, last quizzed date, quiz accuracy history, and performance trends. The difficulty score adjusts based on quiz performance.

**QuizWord Protocol**: Defines the interface for words that can be used in quizzes, supporting both local words and shared dictionary words.

**QuizResult Model**: Represents individual question results within a quiz session, tracking the word, user answer, correct answer, time taken, and difficulty level.

### View Models

**QuizzesListViewModel**: Manages the quiz selection interface, configuration options, and navigation to quiz sessions. Handles word availability checking and quiz preparation.

**SpellingQuizViewModel**: Manages the spelling quiz session state, tracks user input, validates answers, provides feedback, and handles session progression.

**ChooseDefinitionQuizViewModel**: Manages the multiple choice quiz format, generates answer options, tracks user selections, and calculates performance metrics.

**QuizResultsViewModel**: Processes quiz session data, calculates performance metrics, updates word difficulties, and prepares results for display.

**QuizAnalyticsViewModel**: Aggregates quiz performance data, calculates trends, and provides insights into learning progress.

---

## Navigation & User Interactions

### Navigation Flow
The navigation follows a linear progression from quiz selection through configuration, practice, and results analysis. Modal presentations are used for quiz sessions to maintain focus, with push navigation for results and analytics.

### User Interaction Patterns

**Quiz Selection**: Users browse available quiz types and configure settings before starting. The interface provides clear guidance on quiz differences and expected outcomes.

**Session Progression**: Quiz sessions use clear progression indicators and immediate feedback to maintain user engagement and provide learning reinforcement.

**Results Analysis**: Comprehensive results display helps users understand their performance and identify areas for improvement.

**Progress Tracking**: Analytics provide long-term insights into learning progress and help maintain motivation through visible improvement.

**Adaptive Difficulty**: The system automatically adjusts word difficulty based on quiz performance, ensuring appropriate challenge levels.

---

## Service Integration

### Quiz Words Provider
Manages the selection and preparation of words for quiz sessions. Handles filtering by difficulty, tags, and availability, ensuring sufficient words are available for each quiz configuration.

### Quiz Analytics Service
Tracks quiz performance, calculates metrics, and manages the relationship between quiz results and word difficulty adjustments. Handles data aggregation for analytics and progress tracking.

### Core Data Service
Manages quiz session persistence and word difficulty updates. Handles the relationship between quiz performance and word learning progress.

### Haptic Feedback Service
Provides tactile feedback for quiz interactions, enhancing the user experience with appropriate haptic responses for correct/incorrect answers.

### Text-to-Speech Service
Optional pronunciation support for words during quizzes, helping users with auditory learning preferences.

---

## Error Handling & Edge Cases

### Common Error Scenarios

**Insufficient Words**: Handle cases where not enough words are available for the selected quiz configuration with helpful guidance and alternative options.

**Network Errors**: Manage API failures and connectivity issues during word loading with appropriate fallback to cached data.

**Data Corruption**: Handle corrupted quiz session data with graceful recovery and data validation.

**Performance Issues**: Manage slow loading or processing with appropriate loading states and user feedback.

### Edge Cases

**Empty Word Collection**: Provide helpful guidance when no words exist for quizzes, with clear calls-to-action to add words first.

**Perfect Scores**: Handle cases where users achieve perfect scores with appropriate recognition and difficulty adjustment.

**Consistent Poor Performance**: Manage cases where users struggle with all words, providing encouragement and easier word options.

**Large Word Collections**: Optimize performance for users with extensive word collections through efficient querying and pagination.

**Offline Mode**: Gracefully handle offline scenarios with cached word data and deferred analytics updates.

**Session Interruption**: Handle quiz session interruptions with automatic saving and resume functionality.

---

## Implementation Guidelines

### SwiftUI Best Practices

**State Management**: Use appropriate property wrappers for quiz state management - @StateObject for view models, @State for local quiz state, and @Published for reactive updates.

**View Composition**: Break down complex quiz interfaces into smaller, reusable components for better maintainability and testing.

**Animation**: Use smooth animations for transitions between questions and feedback displays to enhance user experience.

### Performance Optimization

**Lazy Loading**: Load quiz words efficiently to minimize startup time and memory usage.

**Background Processing**: Perform analytics calculations and difficulty updates on background queues to maintain UI responsiveness.

**Memory Management**: Properly manage quiz session data and word lists to prevent memory leaks during extended quiz sessions.

### Accessibility

**VoiceOver Support**: Provide comprehensive accessibility labels and hints for all quiz interactions, including answer options and feedback.

**Dynamic Type**: Support system font scaling for users with accessibility needs throughout the quiz interface.

**Color Contrast**: Ensure proper color contrast ratios for all quiz elements, especially for feedback displays and answer options.

### Testing Considerations

**Unit Tests**: Test quiz logic, answer validation, and performance calculations with comprehensive test coverage.

**UI Tests**: Test complete quiz flows to ensure proper functionality across different scenarios and configurations.

**Performance Tests**: Test quiz performance with large word collections and extended sessions to ensure scalability.

**Accessibility Tests**: Verify that all quiz interactions are accessible to users with different needs and preferences.

---

This Quiz Practice Flow document provides comprehensive implementation details for the core quiz functionality in the MyDictionary iOS app, covering all screens, interactions, data flow, and implementation patterns needed for accurate development.
