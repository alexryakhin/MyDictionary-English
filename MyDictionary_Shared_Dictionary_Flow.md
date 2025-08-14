# MyDictionary-English iOS - Shared Dictionary Flow

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
The Shared Dictionary Flow enables collaborative vocabulary learning through shared dictionaries where multiple users can contribute words, rate difficulty, and learn together. The journey begins from the Words tab and flows through dictionary creation, collaboration, and real-time word sharing.

### Flow Diagram
```
Words Tab → Shared Dictionaries List → Create/Join Dictionary → Dictionary Details → Word Collaboration → Real-time Updates
```

### Key User Goals
- **Create shared dictionaries** for collaborative learning
- **Invite collaborators** and manage permissions
- **Contribute words** to shared collections
- **Rate word difficulty** and track group progress
- **Learn from others** through collaborative vocabulary building

---

## Screen-by-Screen Breakdown

### 1. Shared Dictionaries List View

**File**: `SharedDictionariesListView.swift`
**Purpose**: Display user's shared dictionaries and provide access to collaborative features

**UI Components**:
- **Navigation Header**: Custom navigation with large title and add dictionary button
- **Dictionary Cards**: Visual cards showing dictionary info, word count, and collaborators
- **Collaborator Avatars**: Display of dictionary collaborators with roles
- **Dictionary Stats**: Word count, last activity, and sync status
- **Quick Actions**: Join dictionary, create new, and search options
- **Empty State**: Guidance when no shared dictionaries exist
- **Loading State**: Shimmer loading animation while data loads
- **Filter Options**: Filter by ownership, collaboration, or activity

**User Interactions**:
- **View Dictionary**: Navigate to dictionary details and word list
- **Create Dictionary**: Start a new shared dictionary
- **Join Dictionary**: Join existing dictionary via invitation
- **Search Dictionaries**: Find specific shared dictionaries
- **Filter Lists**: Filter by various criteria
- **Quick Actions**: Access common dictionary operations
- **Sync Status**: Check real-time sync status

**State Management**:
The view uses SharedDictionariesListViewModel to manage the list of shared dictionaries, handle real-time updates from Firebase, and manage collaboration permissions.

### 2. Create Shared Dictionary View

**File**: `AddSharedDictionaryView.swift`
**Purpose**: Create new shared dictionaries with initial settings and collaborator invitations

**UI Components**:
- **Navigation Header**: Back button and create button
- **Dictionary Name**: Text field for dictionary name
- **Description**: Multi-line text field for dictionary description
- **Privacy Settings**: Public or private dictionary options
- **Collaborator Invites**: Email input for inviting collaborators
- **Permission Levels**: Set collaborator permissions (view, edit, admin)
- **Initial Words**: Option to add existing words to the dictionary
- **Preview Section**: Show how the dictionary will appear
- **Settings Summary**: Display current configuration

**User Interactions**:
- **Name Dictionary**: Enter dictionary name and description
- **Set Privacy**: Choose public or private access
- **Invite Collaborators**: Add email addresses for invitations
- **Set Permissions**: Define collaborator access levels
- **Add Initial Words**: Select existing words to include
- **Create Dictionary**: Finalize and create the shared dictionary
- **Cancel Creation**: Discard changes and return to list

**State Management**:
The AddSharedDictionaryViewModel manages dictionary creation, collaborator invitations, and initial setup. It handles validation and Firebase integration.

### 3. Shared Dictionary Details View

**File**: `SharedDictionaryDetailsView.swift`
**Purpose**: Manage shared dictionary settings, collaborators, and overall dictionary information

**UI Components**:
- **Navigation Header**: Dictionary title, back button, and settings button
- **Dictionary Info**: Name, description, and creation details
- **Collaborator List**: List of all collaborators with roles and status
- **Permission Management**: Add/remove collaborators and change permissions
- **Dictionary Stats**: Word count, activity, and growth metrics
- **Activity Feed**: Recent changes and contributions
- **Settings Section**: Privacy, notifications, and dictionary options
- **Action Buttons**: Edit dictionary, invite collaborators, delete dictionary

**User Interactions**:
- **View Collaborators**: See all dictionary participants
- **Manage Permissions**: Change collaborator access levels
- **Invite New Users**: Add more collaborators to the dictionary
- **Edit Settings**: Modify dictionary properties and privacy
- **View Activity**: Check recent changes and contributions
- **Delete Dictionary**: Remove shared dictionary (owner only)
- **Export Data**: Download dictionary data

**State Management**:
The SharedDictionaryDetailsViewModel manages dictionary settings, collaborator management, and real-time updates from Firebase.

### 4. Shared Dictionary Words View

**File**: `SharedDictionaryWordsView.swift`
**Purpose**: Display and manage words in the shared dictionary with collaborative features

**UI Components**:
- **Navigation Header**: Dictionary name, back button, and add word button
- **Word List**: List of shared words with collaborative indicators
- **Contributor Info**: Show who added each word
- **Difficulty Ratings**: Group difficulty ratings and statistics
- **Like System**: Collaborative liking and feedback
- **Search and Filter**: Find specific words in the dictionary
- **Sort Options**: Sort by date, difficulty, popularity, or contributor
- **Bulk Actions**: Select multiple words for management

**User Interactions**:
- **View Words**: Browse all words in the shared dictionary
- **Add Words**: Contribute new words to the dictionary
- **Rate Difficulty**: Provide difficulty ratings for words
- **Like Words**: Show appreciation for good contributions
- **Search Words**: Find specific words quickly
- **Filter Words**: Filter by difficulty, contributor, or date
- **Sort Words**: Organize words by various criteria
- **Edit Words**: Modify words (with appropriate permissions)

**State Management**:
The SharedDictionaryWordsViewModel manages the word list, collaborative features, and real-time updates from Firebase.

### 5. Add Word to Shared Dictionary View

**File**: `AddExistingWordToSharedView.swift`
**Purpose**: Add existing personal words to shared dictionaries with collaborative context

**UI Components**:
- **Navigation Header**: Back button and add button
- **Word Selection**: List of user's personal words to choose from
- **Dictionary Context**: Show target shared dictionary information
- **Word Preview**: Display word details before adding
- **Collaborator Info**: Show who will see the word
- **Permission Check**: Verify user has permission to add words
- **Bulk Selection**: Select multiple words to add
- **Confirmation**: Final confirmation before adding

**User Interactions**:
- **Select Words**: Choose words to add to shared dictionary
- **Preview Words**: Review word details before adding
- **Bulk Add**: Add multiple words at once
- **Confirm Addition**: Finalize word addition to shared dictionary
- **Cancel Operation**: Discard changes and return to previous screen
- **View Context**: Understand how words will appear in shared context

**State Management**:
The AddExistingWordToSharedViewModel manages word selection, permission validation, and addition to shared dictionaries.

### 6. Shared Word Details View

**File**: `SharedWordDetailsView.swift`
**Purpose**: View and interact with words in shared dictionaries with collaborative features

**UI Components**:
- **Navigation Header**: Word title, back button, and action buttons
- **Word Information**: Definition, examples, and metadata
- **Contributor Info**: Who added the word and when
- **Collaborative Features**: Like button, difficulty rating, comments
- **Difficulty Statistics**: Group difficulty ratings and trends
- **Activity History**: Recent interactions and changes
- **Permission Indicators**: Show user's permission level
- **Action Buttons**: Edit, delete, share, and other actions

**User Interactions**:
- **View Word Details**: Examine word information and examples
- **Rate Difficulty**: Provide personal difficulty rating
- **Like Word**: Show appreciation for the word
- **Add Comments**: Share thoughts about the word
- **Edit Word**: Modify word details (with permissions)
- **Share Word**: Share word with others outside the dictionary
- **View Statistics**: See group difficulty ratings and trends
- **Report Issues**: Flag inappropriate or incorrect content

**State Management**:
The SharedWordDetailsViewModel manages word display, collaborative interactions, and real-time updates from Firebase.

### 7. Collaborator Management View

**File**: `AddCollaboratorView.swift`
**Purpose**: Invite and manage collaborators for shared dictionaries

**UI Components**:
- **Navigation Header**: Back button and invite button
- **Current Collaborators**: List of existing collaborators with roles
- **Invitation Form**: Email input for new collaborator invitations
- **Permission Selection**: Choose access level for new collaborators
- **Invitation History**: Track sent invitations and their status
- **Role Management**: Change existing collaborator permissions
- **Remove Collaborators**: Remove users from dictionary
- **Bulk Actions**: Manage multiple collaborators at once

**User Interactions**:
- **Invite Users**: Send invitations to new collaborators
- **Set Permissions**: Define access levels for collaborators
- **Manage Roles**: Change existing collaborator permissions
- **Remove Users**: Remove collaborators from dictionary
- **Track Invitations**: Monitor invitation status and responses
- **Bulk Manage**: Handle multiple collaborators simultaneously
- **View History**: Check invitation and collaboration history

**State Management**:
The AddCollaboratorViewModel manages collaborator invitations, permission management, and real-time collaboration updates.

---

## Data Models & State Management

### Core Data Models

**SharedDictionary Entity**: Represents collaborative dictionaries with metadata including name, description, privacy settings, creation date, and owner information.

**SharedWord Entity**: Represents words in shared dictionaries with collaborative features including contributor information, difficulty ratings, likes, and activity history.

**Collaborator Entity**: Manages user relationships with shared dictionaries including roles, permissions, invitation status, and activity tracking.

**CollaborationEvent Model**: Tracks collaborative activities including word additions, difficulty ratings, likes, and comments for analytics and activity feeds.

**Invitation Model**: Manages collaborator invitations with status tracking, expiration handling, and response management.

### View Models

**SharedDictionariesListViewModel**: Manages the list of shared dictionaries, handles real-time updates, and manages collaboration permissions and navigation.

**AddSharedDictionaryViewModel**: Handles dictionary creation, initial setup, collaborator invitations, and Firebase integration for new shared dictionaries.

**SharedDictionaryDetailsViewModel**: Manages dictionary settings, collaborator management, and real-time updates from Firebase for existing shared dictionaries.

**SharedDictionaryWordsViewModel**: Manages the word list in shared dictionaries, collaborative features, and real-time synchronization with Firebase.

**AddExistingWordToSharedViewModel**: Handles adding personal words to shared dictionaries with permission validation and collaborative context.

**SharedWordDetailsViewModel**: Manages word display in shared context, collaborative interactions, and real-time updates from Firebase.

**AddCollaboratorViewModel**: Manages collaborator invitations, permission management, and real-time collaboration updates.

---

## Navigation & User Interactions

### Navigation Flow
The navigation follows a hierarchical structure starting from the Words tab, with push navigation for dictionary details and modal presentations for creation and management operations.

### User Interaction Patterns

**Collaborative Creation**: Users can create shared dictionaries and invite collaborators through intuitive invitation flows.

**Real-time Updates**: All collaborative activities are synchronized in real-time across all participants.

**Permission-based Actions**: User actions are restricted based on their permission level in each dictionary.

**Progressive Disclosure**: Complex collaborative features are revealed progressively as users explore the functionality.

**Contextual Feedback**: Users receive immediate feedback on collaborative actions and permission changes.

**Activity Tracking**: All collaborative activities are tracked and displayed in activity feeds for transparency.

---

## Service Integration

### Dictionary Service
Core service for managing shared dictionaries, real-time collaboration, and Firebase integration for collaborative features.

### Collaboration Service
Handles collaborative interactions including difficulty ratings, likes, comments, and activity tracking across shared dictionaries.

### Invitation Service
Manages collaborator invitations, email notifications, and invitation status tracking with expiration handling.

### Permission Service
Handles user permissions, role management, and access control for shared dictionary features.

### Real-time Sync Service
Manages real-time synchronization of collaborative data across all participants using Firebase Firestore.

### Notification Service
Handles collaborative notifications including invitations, word additions, and activity updates to maintain engagement.

---

## Error Handling & Edge Cases

### Common Error Scenarios

**Network Connectivity**: Handle offline scenarios with local caching and sync when connectivity returns.

**Permission Errors**: Manage permission failures with clear error messages and guidance on required permissions.

**Invitation Failures**: Handle invitation delivery failures, expired invitations, and invalid email addresses.

**Sync Conflicts**: Manage data conflicts in collaborative editing with clear resolution options and user choice.

**Storage Limits**: Handle Firebase storage limits and quota management for large collaborative dictionaries.

### Edge Cases

**New Collaborators**: Provide helpful onboarding for new dictionary participants with guided tours and feature explanations.

**Inactive Collaborators**: Handle users who become inactive with appropriate notification and cleanup processes.

**Large Dictionaries**: Optimize performance for dictionaries with many words and collaborators through efficient data loading and pagination.

**Permission Changes**: Handle permission revocation and role changes with appropriate user notification and data access updates.

**Dictionary Deletion**: Manage dictionary deletion with data backup options and collaborator notification processes.

**Privacy Changes**: Handle dictionary privacy setting changes with appropriate collaborator notification and access updates.

---

## Implementation Guidelines

### SwiftUI Best Practices

**Real-time Updates**: Implement efficient real-time data synchronization using Firebase listeners with proper cleanup and error handling.

**Permission Management**: Use clear permission indicators and disable actions appropriately based on user permissions.

**Collaborative UI**: Design interfaces that clearly show collaborative features and user contributions.

**Activity Feedback**: Provide immediate visual feedback for collaborative actions to maintain user engagement.

### Performance Optimization

**Lazy Loading**: Load collaborative data progressively to handle large dictionaries and many collaborators efficiently.

**Caching Strategy**: Implement intelligent caching for collaborative data to minimize loading times and improve responsiveness.

**Background Sync**: Perform collaborative data synchronization on background queues to maintain UI responsiveness.

**Memory Management**: Optimize memory usage for collaborative features through efficient data structures and cleanup.

### Accessibility

**Collaborative Indicators**: Ensure all collaborative features are accessible with proper labels and descriptions.

**Permission Feedback**: Provide clear accessibility feedback for permission-based actions and restrictions.

**Activity Descriptions**: Make collaborative activities accessible with proper descriptions and context.

**Real-time Updates**: Ensure real-time updates are accessible with appropriate announcements and status changes.

### Testing Considerations

**Collaborative Testing**: Test collaborative features with multiple users and different permission levels to ensure proper functionality.

**Real-time Sync Testing**: Verify real-time synchronization across different network conditions and device states.

**Permission Testing**: Test permission management thoroughly with various user roles and permission changes.

**Invitation Testing**: Test collaborator invitation flows including email delivery, expiration, and response handling.

---

This Shared Dictionary Flow document provides comprehensive implementation details for the collaborative dictionary functionality in the MyDictionary iOS app, covering all screens, interactions, data flow, and implementation patterns needed for accurate development.
