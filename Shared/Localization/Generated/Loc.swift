// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Loc {
  public enum Actions {
    /// Add
    public static let add = Loc.tr("Actions", "add", fallback: "Add")
    /// Back
    public static let back = Loc.tr("Actions", "back", fallback: "Back")
    /// Cancel
    public static let cancel = Loc.tr("Actions", "cancel", fallback: "Cancel")
    /// Check
    public static let check = Loc.tr("Actions", "check", fallback: "Check")
    /// Clear
    public static let clear = Loc.tr("Actions", "clear", fallback: "Clear")
    /// Confirm
    public static let confirm = Loc.tr("Actions", "confirm", fallback: "Confirm")
    /// Copy
    public static let copy = Loc.tr("Actions", "copy", fallback: "Copy")
    /// Create
    public static let create = Loc.tr("Actions", "create", fallback: "Create")
    /// Delete
    public static let delete = Loc.tr("Actions", "delete", fallback: "Delete")
    /// Done
    public static let done = Loc.tr("Actions", "done", fallback: "Done")
    /// Download
    public static let download = Loc.tr("Actions", "download", fallback: "Download")
    /// Edit
    public static let edit = Loc.tr("Actions", "edit", fallback: "Edit")
    /// Email Address
    public static let emailAddress = Loc.tr("Actions", "email_address", fallback: "Email Address")
    /// Exit
    public static let exit = Loc.tr("Actions", "exit", fallback: "Exit")
    /// Export Words
    public static let exportWords = Loc.tr("Actions", "export_words", fallback: "Export Words")
    /// Import Words
    public static let importWords = Loc.tr("Actions", "import_words", fallback: "Import Words")
    /// Learn More
    public static let learnMore = Loc.tr("Actions", "learn_more", fallback: "Learn More")
    /// Link Apple
    public static let linkApple = Loc.tr("Actions", "link_apple", fallback: "Link Apple")
    /// Link Google
    public static let linkGoogle = Loc.tr("Actions", "link_google", fallback: "Link Google")
    /// Listen
    public static let listen = Loc.tr("Actions", "listen", fallback: "Listen")
    /// Loading...
    public static let loading = Loc.tr("Actions", "loading", fallback: "Loading...")
    /// Make Editor
    public static let makeEditor = Loc.tr("Actions", "make_editor", fallback: "Make Editor")
    /// Make Viewer
    public static let makeViewer = Loc.tr("Actions", "make_viewer", fallback: "Make Viewer")
    /// Manage
    public static let manage = Loc.tr("Actions", "manage", fallback: "Manage")
    /// Name
    public static let name = Loc.tr("Actions", "name", fallback: "Name")
    /// Next
    public static let next = Loc.tr("Actions", "next", fallback: "Next")
    /// No
    public static let no = Loc.tr("Actions", "no", fallback: "No")
    /// OK
    public static let ok = Loc.tr("Actions", "ok", fallback: "OK")
    /// Refresh
    public static let refresh = Loc.tr("Actions", "refresh", fallback: "Refresh")
    /// Remove
    public static let remove = Loc.tr("Actions", "remove", fallback: "Remove")
    /// Request
    public static let request = Loc.tr("Actions", "request", fallback: "Request")
    /// Reset
    public static let reset = Loc.tr("Actions", "reset", fallback: "Reset")
    /// Retry
    public static let retry = Loc.tr("Actions", "retry", fallback: "Retry")
    /// Save
    public static let save = Loc.tr("Actions", "save", fallback: "Save")
    /// Save Word
    public static let saveWord = Loc.tr("Actions", "save_word", fallback: "Save Word")
    /// Search
    public static let search = Loc.tr("Actions", "search", fallback: "Search")
    /// Select
    public static let select = Loc.tr("Actions", "select", fallback: "Select")
    /// Select an idiom
    public static let selectIdiom = Loc.tr("Actions", "select_idiom", fallback: "Select an idiom")
    /// Select a quiz
    public static let selectQuiz = Loc.tr("Actions", "select_quiz", fallback: "Select a quiz")
    /// Select a value
    public static let selectValue = Loc.tr("Actions", "select_value", fallback: "Select a value")
    /// Select a word
    public static let selectWord = Loc.tr("Actions", "select_word", fallback: "Select a word")
    /// Send
    public static let send = Loc.tr("Actions", "send", fallback: "Send")
    /// Settings
    public static let settings = Loc.tr("Actions", "settings", fallback: "Settings")
    /// Show
    public static let show = Loc.tr("Actions", "show", fallback: "Show")
    /// Sign In
    public static let signIn = Loc.tr("Actions", "sign_in", fallback: "Sign In")
    /// Sign Out
    public static let signOut = Loc.tr("Actions", "sign_out", fallback: "Sign Out")
    /// Skip for Now
    public static let skipForNow = Loc.tr("Actions", "skip_for_now", fallback: "Skip for Now")
    /// Stop Watching
    public static let stopWatching = Loc.tr("Actions", "stop_watching", fallback: "Stop Watching")
    /// Sync
    public static let sync = Loc.tr("Actions", "sync", fallback: "Sync")
    /// Test
    public static let test = Loc.tr("Actions", "test", fallback: "Test")
    /// Toggle Favorite
    public static let toggleFavorite = Loc.tr("Actions", "toggle_favorite", fallback: "Toggle Favorite")
    /// Toggle Like
    public static let toggleLike = Loc.tr("Actions", "toggle_like", fallback: "Toggle Like")
    /// Try Again
    public static let tryAgain = Loc.tr("Actions", "try_again", fallback: "Try Again")
    /// Upgrade
    public static let upgrade = Loc.tr("Actions", "upgrade", fallback: "Upgrade")
    /// Upload
    public static let upload = Loc.tr("Actions", "upload", fallback: "Upload")
    /// Verify
    public static let verify = Loc.tr("Actions", "verify", fallback: "Verify")
    /// View All
    public static let viewAll = Loc.tr("Actions", "view_all", fallback: "View All")
    /// Yes
    public static let yes = Loc.tr("Actions", "yes", fallback: "Yes")
  }
  public enum Ai {
    /// Sign in to use AI features
    public static let aiSignInRequired = Loc.tr("AI", "ai_sign_in_required", fallback: "Sign in to use AI features")
    /// To use AI-powered definitions, please sign in to your account.
    public static let aiSignInRequiredMessage = Loc.tr("AI", "ai_sign_in_required_message", fallback: "To use AI-powered definitions, please sign in to your account.")
    /// Daily AI usage limit reached. Upgrade to Pro for unlimited AI-powered definitions.
    public static let aiUsageLimitExceeded = Loc.tr("AI", "ai_usage_limit_exceeded", fallback: "Daily AI usage limit reached. Upgrade to Pro for unlimited AI-powered definitions.")
    public enum AiAnimation {
      /// AI is analyzing...
      public static let analyzing = Loc.tr("AI", "ai_animation.analyzing", fallback: "AI is analyzing...")
      /// Analyzing your word with advanced AI
      public static let analyzingWord = Loc.tr("AI", "ai_animation.analyzing_word", fallback: "Analyzing your word with advanced AI")
      /// Finding the perfect definitions for you
      public static let findingDefinitions = Loc.tr("AI", "ai_animation.finding_definitions", fallback: "Finding the perfect definitions for you")
      /// AI is learning...
      public static let learning = Loc.tr("AI", "ai_animation.learning", fallback: "AI is learning...")
      /// AI Processing...
      public static let processing = Loc.tr("AI", "ai_animation.processing", fallback: "AI Processing...")
      /// Processing your word with neural networks
      public static let processingNeural = Loc.tr("AI", "ai_animation.processing_neural", fallback: "Processing your word with neural networks")
      /// AI is thinking...
      public static let thinking = Loc.tr("AI", "ai_animation.thinking", fallback: "AI is thinking...")
    }
    public enum AiLoading {
      /// Analyzing context...
      public static let analyzingContext = Loc.tr("AI", "ai_loading.analyzing_context", fallback: "Analyzing context...")
      /// AI is computing...
      public static let computing = Loc.tr("AI", "ai_loading.computing", fallback: "AI is computing...")
      /// Finding definitions...
      public static let findingDefinitions = Loc.tr("AI", "ai_loading.finding_definitions", fallback: "Finding definitions...")
      /// Generating insights...
      public static let generatingInsights = Loc.tr("AI", "ai_loading.generating_insights", fallback: "Generating insights...")
      /// Learning patterns...
      public static let learningPatterns = Loc.tr("AI", "ai_loading.learning_patterns", fallback: "Learning patterns...")
      /// Processing language...
      public static let processingLanguage = Loc.tr("AI", "ai_loading.processing_language", fallback: "Processing language...")
      /// Running algorithms...
      public static let runningAlgorithms = Loc.tr("AI", "ai_loading.running_algorithms", fallback: "Running algorithms...")
      /// Understanding meaning...
      public static let understandingMeaning = Loc.tr("AI", "ai_loading.understanding_meaning", fallback: "Understanding meaning...")
    }
    public enum AiLoadingDesc {
      /// Applying machine learning
      public static let applyingMachineLearning = Loc.tr("AI", "ai_loading_desc.applying_machine_learning", fallback: "Applying machine learning")
      /// Creating comprehensive definitions
      public static let creatingDefinitions = Loc.tr("AI", "ai_loading_desc.creating_definitions", fallback: "Creating comprehensive definitions")
      /// Examining word relationships
      public static let examiningRelationships = Loc.tr("AI", "ai_loading_desc.examining_relationships", fallback: "Examining word relationships")
      /// Extracting semantic meaning
      public static let extractingSemantic = Loc.tr("AI", "ai_loading_desc.extracting_semantic", fallback: "Extracting semantic meaning")
      /// Identifying usage patterns
      public static let identifyingPatterns = Loc.tr("AI", "ai_loading_desc.identifying_patterns", fallback: "Identifying usage patterns")
      /// Running advanced algorithms
      public static let runningAlgorithms = Loc.tr("AI", "ai_loading_desc.running_algorithms", fallback: "Running advanced algorithms")
      /// Searching through knowledge base
      public static let searchingKnowledge = Loc.tr("AI", "ai_loading_desc.searching_knowledge", fallback: "Searching through knowledge base")
      /// Understanding language nuances
      public static let understandingNuances = Loc.tr("AI", "ai_loading_desc.understanding_nuances", fallback: "Understanding language nuances")
    }
    public enum AiUsage {
      /// %d AI requests remaining today
      public static func remainingRequests(_ p1: Int) -> String {
        return Loc.tr("AI", "ai_usage.remaining_requests", p1, fallback: "%d AI requests remaining today")
      }
      /// Unlimited AI requests with Pro
      public static let unlimitedRequests = Loc.tr("AI", "ai_usage.unlimited_requests", fallback: "Unlimited AI requests with Pro")
      /// Get unlimited AI-powered definitions, advanced analytics, and more premium features.
      public static let upgradeBannerMessage = Loc.tr("AI", "ai_usage.upgrade_banner_message", fallback: "Get unlimited AI-powered definitions, advanced analytics, and more premium features.")
      /// Upgrade to Pro for Unlimited AI
      public static let upgradeBannerTitle = Loc.tr("AI", "ai_usage.upgrade_banner_title", fallback: "Upgrade to Pro for Unlimited AI")
      /// Upgrade to Pro
      public static let upgradeButton = Loc.tr("AI", "ai_usage.upgrade_button", fallback: "Upgrade to Pro")
    }
  }
  public enum Analytics {
    /// Accuracy
    public static let accuracy = Loc.tr("Analytics", "accuracy", fallback: "Accuracy")
    /// All Results
    public static let allResults = Loc.tr("Analytics", "all_results", fallback: "All Results")
    /// Best
    public static let best = Loc.tr("Analytics", "best", fallback: "Best")
    /// Complete your first quiz to see results here
    public static let completeFirstQuiz = Loc.tr("Analytics", "complete_first_quiz", fallback: "Complete your first quiz to see results here")
    /// Complete your first quiz to see activity here
    public static let completeFirstQuizActivity = Loc.tr("Analytics", "complete_first_quiz_activity", fallback: "Complete your first quiz to see activity here")
    /// Complete your first quiz to see results here
    public static let completeFirstQuizResults = Loc.tr("Analytics", "complete_first_quiz_results", fallback: "Complete your first quiz to see results here")
    /// Complete quizzes to see your vocabulary growth over time
    public static let completeQuizzesGrowth = Loc.tr("Analytics", "complete_quizzes_growth", fallback: "Complete quizzes to see your vocabulary growth over time")
    /// Complete quizzes to see your vocabulary growth over time
    public static let completeQuizzesGrowthData = Loc.tr("Analytics", "complete_quizzes_growth_data", fallback: "Complete quizzes to see your vocabulary growth over time")
    /// Correct Answers
    public static let correctAnswers = Loc.tr("Analytics", "correct_answers", fallback: "Correct Answers")
    /// Difficulty Statistics
    public static let difficultyStatistics = Loc.tr("Analytics", "difficulty_statistics", fallback: "Difficulty Statistics")
    /// Duration
    public static let duration = Loc.tr("Analytics", "duration", fallback: "Duration")
    /// How other users rate this word's difficulty
    public static let howOtherUsersRateDifficulty = Loc.tr("Analytics", "how_other_users_rate_difficulty", fallback: "How other users rate this word's difficulty")
    /// Individual Ratings
    public static let individualRatings = Loc.tr("Analytics", "individual_ratings", fallback: "Individual Ratings")
    /// Last %@
    public static func lastTimePeriod(_ p1: Any) -> String {
      return Loc.tr("Analytics", "last_time_period", String(describing: p1), fallback: "Last %@")
    }
    /// Less
    public static let less = Loc.tr("Analytics", "less", fallback: "Less")
    /// Loading progress data...
    public static let loadingProgressData = Loc.tr("Analytics", "loading_progress_data", fallback: "Loading progress data...")
    /// More
    public static let more = Loc.tr("Analytics", "more", fallback: "More")
    /// No difficulty ratings yet
    public static let noDifficultyRatingsYet = Loc.tr("Analytics", "no_difficulty_ratings_yet", fallback: "No difficulty ratings yet")
    /// No Growth Data Yet
    public static let noGrowthDataYet = Loc.tr("Analytics", "no_growth_data_yet", fallback: "No Growth Data Yet")
    /// No Quiz Activity
    public static let noQuizActivity = Loc.tr("Analytics", "no_quiz_activity", fallback: "No Quiz Activity")
    /// No Quiz Results Yet
    public static let noQuizResultsYet = Loc.tr("Analytics", "no_quiz_results_yet", fallback: "No Quiz Results Yet")
    /// Overview
    public static let overview = Loc.tr("Analytics", "overview", fallback: "Overview")
    /// pts
    public static let points = Loc.tr("Analytics", "points", fallback: "pts")
    /// Practice Time
    public static let practiceTime = Loc.tr("Analytics", "practice_time", fallback: "Practice Time")
    /// Progress
    public static let progress = Loc.tr("Analytics", "progress", fallback: "Progress")
    /// Quiz Activity
    public static let quizActivity = Loc.tr("Analytics", "quiz_activity", fallback: "Quiz Activity")
    /// Recent Quiz Results
    public static let recentQuizResults = Loc.tr("Analytics", "recent_quiz_results", fallback: "Recent Quiz Results")
    /// Score
    public static let score = Loc.tr("Analytics", "score", fallback: "Score")
    /// Sessions
    public static let sessions = Loc.tr("Analytics", "sessions", fallback: "Sessions")
    /// Streak
    public static let streak = Loc.tr("Analytics", "streak", fallback: "Streak")
    /// Time Period
    public static let timePeriod = Loc.tr("Analytics", "time_period", fallback: "Time Period")
    /// Total Questions
    public static let totalQuestions = Loc.tr("Analytics", "total_questions", fallback: "Total Questions")
    /// Total Ratings
    public static let totalRatings = Loc.tr("Analytics", "total_ratings", fallback: "Total Ratings")
    /// View Detailed Statistics
    public static let viewDetailedStatistics = Loc.tr("Analytics", "view_detailed_statistics", fallback: "View Detailed Statistics")
    /// Vocabulary Growth
    public static let vocabularyGrowth = Loc.tr("Analytics", "vocabulary_growth", fallback: "Vocabulary Growth")
    /// Words Played
    public static let wordsPlayed = Loc.tr("Analytics", "words_played", fallback: "Words Played")
    public enum TimePeriod {
      /// Month
      public static let month = Loc.tr("Analytics", "time_period.month", fallback: "Month")
      /// Week
      public static let week = Loc.tr("Analytics", "time_period.week", fallback: "Week")
      /// Year
      public static let year = Loc.tr("Analytics", "time_period.year", fallback: "Year")
    }
  }
  public enum Auth {
    /// Access your subscription on all your devices
    public static let accessSubscriptionAllDevices = Loc.tr("Auth", "access_subscription_all_devices", fallback: "Access your subscription on all your devices")
    /// Account Linking
    public static let accountLinking = Loc.tr("Auth", "account_linking", fallback: "Account Linking")
    /// To access your subscription on Android devices, you need to link a Google account. For cross-platform subscription sharing, link both accounts.
    public static let accountLinkingDescription = Loc.tr("Auth", "account_linking_description", fallback: "To access your subscription on Android devices, you need to link a Google account. For cross-platform subscription sharing, link both accounts.")
    /// Failed to link accounts. Please try again.
    public static let accountLinkingFailed = Loc.tr("Auth", "account_linking_failed", fallback: "Failed to link accounts. Please try again.")
    /// Account Registration
    public static let accountRegistration = Loc.tr("Auth", "account_registration", fallback: "Account Registration")
    /// Accounts linked successfully
    public static let accountsLinkedSuccessfully = Loc.tr("Auth", "accounts_linked_successfully", fallback: "Accounts linked successfully")
    /// You have an active subscription!
    public static let activeSubscriptionNotification = Loc.tr("Auth", "active_subscription_notification", fallback: "You have an active subscription!")
    /// All your vocabulary words, definitions, and progress will remain on this device. You can continue using the app offline.
    public static let allVocabularyRemainDevice = Loc.tr("Auth", "all_vocabulary_remain_device", fallback: "All your vocabulary words, definitions, and progress will remain on this device. You can continue using the app offline.")
    /// Apple ID
    public static let appleId = Loc.tr("Auth", "apple_id", fallback: "Apple ID")
    /// Backup your data securely in the cloud
    public static let backupDataSecurely = Loc.tr("Auth", "backup_data_securely", fallback: "Backup your data securely in the cloud")
    /// You can always sign in later from Settings
    public static let canAlwaysSignInLater = Loc.tr("Auth", "can_always_sign_in_later", fallback: "You can always sign in later from Settings")
    /// Cancel
    public static let cancel = Loc.tr("Auth", "cancel", fallback: "Cancel")
    /// Cloud sync will be disabled
    public static let cloudSyncDisabled = Loc.tr("Auth", "cloud_sync_disabled", fallback: "Cloud sync will be disabled")
    /// For cross-platform subscription sharing
    public static let crossPlatformButtonDescription = Loc.tr("Auth", "cross_platform_button_description", fallback: "For cross-platform subscription sharing")
    /// Current Account
    public static let currentAccount = Loc.tr("Auth", "current_account", fallback: "Current Account")
    /// Edit Nickname
    public static let editNickname = Loc.tr("Auth", "edit_nickname", fallback: "Edit Nickname")
    /// Email
    public static let email = Loc.tr("Auth", "email", fallback: "Email")
    /// Enter email address
    public static let enterEmailAddress = Loc.tr("Auth", "enter_email_address", fallback: "Enter email address")
    /// Enter name
    public static let enterName = Loc.tr("Auth", "enter_name", fallback: "Enter name")
    /// Enter nickname
    public static let enterNickname = Loc.tr("Auth", "enter_nickname", fallback: "Enter nickname")
    /// Find User by Email
    public static let findUserByEmail = Loc.tr("Auth", "find_user_by_email", fallback: "Find User by Email")
    /// Find User by Nickname
    public static let findUserByNickname = Loc.tr("Auth", "find_user_by_nickname", fallback: "Find User by Nickname")
    /// Found User
    public static let foundUser = Loc.tr("Auth", "found_user", fallback: "Found User")
    /// Google Account
    public static let googleAccount = Loc.tr("Auth", "google_account", fallback: "Google Account")
    /// Link additional accounts
    public static let linkAdditionalAccounts = Loc.tr("Auth", "link_additional_accounts", fallback: "Link additional accounts")
    /// Link Apple
    public static let linkApple = Loc.tr("Auth", "link_apple", fallback: "Link Apple")
    /// Link Apple ID
    public static let linkAppleForCrossPlatform = Loc.tr("Auth", "link_apple_for_cross_platform", fallback: "Link Apple ID")
    /// Link Google
    public static let linkGoogle = Loc.tr("Auth", "link_google", fallback: "Link Google")
    /// Link Google Account
    public static let linkGoogleForAndroid = Loc.tr("Auth", "link_google_for_android", fallback: "Link Google Account")
    /// Linked Accounts
    public static let linkedAccounts = Loc.tr("Auth", "linked_accounts", fallback: "Linked Accounts")
    /// Network error. Please check your connection.
    public static let networkError = Loc.tr("Auth", "network_error", fallback: "Network error. Please check your connection.")
    /// Nickname
    public static let nickname = Loc.tr("Auth", "nickname", fallback: "Nickname")
    /// This nickname is already taken. Please choose a different one.
    public static let nicknameAlreadyTaken = Loc.tr("Auth", "nickname_already_taken", fallback: "This nickname is already taken. Please choose a different one.")
    /// Nickname cannot be empty
    public static let nicknameCannotBeEmpty = Loc.tr("Auth", "nickname_cannot_be_empty", fallback: "Nickname cannot be empty")
    /// Current nickname
    public static let nicknameCurrent = Loc.tr("Auth", "nickname_current", fallback: "Current nickname")
    /// Set a unique nickname that others can use to find and add you to shared dictionaries. This is more convenient than using email addresses.
    public static let nicknameDescription = Loc.tr("Auth", "nickname_description", fallback: "Set a unique nickname that others can use to find and add you to shared dictionaries. This is more convenient than using email addresses.")
    /// Nickname can only contain letters, numbers, and underscores.
    public static let nicknameInvalidFormat = Loc.tr("Auth", "nickname_invalid_format", fallback: "Nickname can only contain letters, numbers, and underscores.")
    /// Nickname is not set
    public static let nicknameNotSet = Loc.tr("Auth", "nickname_not_set", fallback: "Nickname is not set")
    /// No linked accounts
    public static let noLinkedAccounts = Loc.tr("Auth", "no_linked_accounts", fallback: "No linked accounts")
    /// No worries! We won't remove your words.
    public static let noWorriesWontRemoveWords = Loc.tr("Auth", "no_worries_wont_remove_words", fallback: "No worries! We won't remove your words.")
    /// Profile
    public static let profile = Loc.tr("Auth", "profile", fallback: "Profile")
    /// You can register anytime from Settings to enable these features
    public static let registerAnytimeFromSettings = Loc.tr("Auth", "register_anytime_from_settings", fallback: "You can register anytime from Settings to enable these features")
    /// Register to access your subscription across all your devices and sync your progress
    public static let registerForCrossPlatformAccess = Loc.tr("Auth", "register_for_cross_platform_access", fallback: "Register to access your subscription across all your devices and sync your progress")
    /// Register Now
    public static let registerNow = Loc.tr("Auth", "register_now", fallback: "Register Now")
    /// Register to unlock cross-platform access
    public static let registerToUnlockCrossPlatform = Loc.tr("Auth", "register_to_unlock_cross_platform", fallback: "Register to unlock cross-platform access")
    /// Registration Benefits
    public static let registrationBenefits = Loc.tr("Auth", "registration_benefits", fallback: "Registration Benefits")
    /// Save
    public static let save = Loc.tr("Auth", "save", fallback: "Save")
    /// Search by
    public static let searchBy = Loc.tr("Auth", "search_by", fallback: "Search by")
    /// Search Method
    public static let searchMethod = Loc.tr("Auth", "search_method", fallback: "Search Method")
    /// Sign in before subscribing
    public static let signInBeforeSubscribing = Loc.tr("Auth", "sign_in_before_subscribing", fallback: "Sign in before subscribing")
    /// Failed to sign in. Please try again.
    public static let signInFailed = Loc.tr("Auth", "sign_in_failed", fallback: "Failed to sign in. Please try again.")
    /// You need to sign in to access Pro features like %@.
    public static func signInRequiredForProFeatures(_ p1: Any) -> String {
      return Loc.tr("Auth", "sign_in_required_for_pro_features", String(describing: p1), fallback: "You need to sign in to access Pro features like %@.")
    }
    /// You need to sign in to restore your purchases.
    public static let signInRequiredForRestore = Loc.tr("Auth", "sign_in_required_for_restore", fallback: "You need to sign in to restore your purchases.")
    /// Sign in to access your word lists across all your devices and collaborate with others.
    public static let signInToAccessWordLists = Loc.tr("Auth", "sign_in_to_access_word_lists", fallback: "Sign in to access your word lists across all your devices and collaborate with others.")
    /// Sign in to sync your word lists
    public static let signInToSyncWordLists = Loc.tr("Auth", "sign_in_to_sync_word_lists", fallback: "Sign in to sync your word lists")
    /// Sign in with Google
    public static let signInWithGoogle = Loc.tr("Auth", "sign_in_with_google", fallback: "Sign in with Google")
    /// Sign Out
    public static let signOut = Loc.tr("Auth", "sign_out", fallback: "Sign Out")
    /// Sign Out
    public static let signOutConfirmation = Loc.tr("Auth", "sign_out_confirmation", fallback: "Sign Out")
    /// Something went wrong while signing out. Please try again later.
    public static let signOutErrorMessage = Loc.tr("Auth", "sign_out_error_message", fallback: "Something went wrong while signing out. Please try again later.")
    /// Oh no!
    public static let signOutErrorTitle = Loc.tr("Auth", "sign_out_error_title", fallback: "Oh no!")
    /// Failed to sign out. Please try again.
    public static let signOutFailed = Loc.tr("Auth", "sign_out_failed", fallback: "Failed to sign out. Please try again.")
    /// Subscription Access Restricted
    public static let subscriptionAccessRestricted = Loc.tr("Auth", "subscription_access_restricted", fallback: "Subscription Access Restricted")
    /// This subscription is associated with a different account. Please sign in with the account that purchased this subscription to access Pro features.
    public static let subscriptionAssociatedDifferentAccount = Loc.tr("Auth", "subscription_associated_different_account", fallback: "This subscription is associated with a different account. Please sign in with the account that purchased this subscription to access Pro features.")
    /// Sync your progress across iOS and Android
    public static let syncProgressCrossPlatform = Loc.tr("Auth", "sync_progress_cross_platform", fallback: "Sync your progress across iOS and Android")
    /// Unknown User
    public static let unknownUser = Loc.tr("Auth", "unknown_user", fallback: "Unknown User")
    /// User not found
    public static let userNotFound = Loc.tr("Auth", "user_not_found", fallback: "User not found")
    /// No user found with the provided information. Please check your search and try again.
    public static let userNotFoundMessage = Loc.tr("Auth", "user_not_found_message", fallback: "No user found with the provided information. Please check your search and try again.")
    /// Your vocabulary will stay on this device. If you sign in with another account, your data will be combined.
    public static let vocabularyStayOnDevice = Loc.tr("Auth", "vocabulary_stay_on_device", fallback: "Your vocabulary will stay on this device. If you sign in with another account, your data will be combined.")
    /// Word lists and shared data will be cleared. If you sign in with another account, your local words will be combined with the new account's data.
    public static let wordListsSharedDataCleared = Loc.tr("Auth", "word_lists_shared_data_cleared", fallback: "Word lists and shared data will be cleared. If you sign in with another account, your local words will be combined with the new account's data.")
    /// Your words are safe
    public static let yourWordsAreSafe = Loc.tr("Auth", "your_words_are_safe", fallback: "Your words are safe")
  }
  public enum Coffee {
    /// Buy Me a Coffee
    public static let buyMeACoffee = Loc.tr("Coffee", "buy_me_a_coffee", fallback: "Buy Me a Coffee")
    /// Enjoying the app?
    public static let enjoyingTheApp = Loc.tr("Coffee", "enjoying_the_app", fallback: "Enjoying the app?")
    /// If My Dictionary has been helpful in your learning journey, consider buying me a coffee! ☕️
    public static let helpfulLearningJourney = Loc.tr("Coffee", "helpful_learning_journey", fallback: "If My Dictionary has been helpful in your learning journey, consider buying me a coffee! ☕️")
    /// Maybe Later
    public static let maybeLater = Loc.tr("Coffee", "maybe_later", fallback: "Maybe Later")
  }
  public enum Errors {
    /// Authentication required
    public static let authenticationRequired = Loc.tr("Errors", "authentication_required", fallback: "Authentication required")
    /// Cannot access security scoped resource
    public static let cannotAccessSecurityScopedResource = Loc.tr("Errors", "cannot_access_security_scoped_resource", fallback: "Cannot access security scoped resource")
    /// Cannot play audio
    public static let cannotPlayAudio = Loc.tr("Errors", "cannot_play_audio", fallback: "Cannot play audio")
    /// Cannot setup audio session
    public static let cannotSetupAudioSession = Loc.tr("Errors", "cannot_setup_audio_session", fallback: "Cannot setup audio session")
    /// Data corrupted
    public static let dataCorrupted = Loc.tr("Errors", "data_corrupted", fallback: "Data corrupted")
    /// Decoding error
    public static let decodingError = Loc.tr("Errors", "decoding_error", fallback: "Decoding error")
    /// Delete failed
    public static let deleteFailed = Loc.tr("Errors", "delete_failed", fallback: "Delete failed")
    /// Device muted or volume too low
    public static let deviceMutedOrVolumeLow = Loc.tr("Errors", "device_muted_or_volume_low", fallback: "Device muted or volume too low")
    /// You can only create one shared dictionary with the free plan. Upgrade to Pro for unlimited shared dictionaries.
    public static let dictionaryLimitReached = Loc.tr("Errors", "dictionary_limit_reached", fallback: "You can only create one shared dictionary with the free plan. Upgrade to Pro for unlimited shared dictionaries.")
    /// Dictionary not found
    public static let dictionaryNotFound = Loc.tr("Errors", "dictionary_not_found", fallback: "Dictionary not found")
    /// Error
    public static let error = Loc.tr("Errors", "error", fallback: "Error")
    /// Error removing idiom
    public static let errorRemovingIdiom = Loc.tr("Errors", "error_removing_idiom", fallback: "Error removing idiom")
    /// Error removing word
    public static let errorRemovingWord = Loc.tr("Errors", "error_removing_word", fallback: "Error removing word")
    /// Error saving idiom
    public static let errorSavingIdiom = Loc.tr("Errors", "error_saving_idiom", fallback: "Error saving idiom")
    /// Error saving word
    public static let errorSavingWord = Loc.tr("Errors", "error_saving_word", fallback: "Error saving word")
    /// Error updating idiom examples
    public static let errorUpdatingIdiomExamples = Loc.tr("Errors", "error_updating_idiom_examples", fallback: "Error updating idiom examples")
    /// Error updating word examples
    public static let errorUpdatingWordExamples = Loc.tr("Errors", "error_updating_word_examples", fallback: "Error updating word examples")
    /// Export failed
    public static let exportFailed = Loc.tr("Errors", "export_failed", fallback: "Export failed")
    /// Export limit exceeded. Upgrade to Pro for unlimited exports.
    public static let exportLimitExceeded = Loc.tr("Errors", "export_limit_exceeded", fallback: "Export limit exceeded. Upgrade to Pro for unlimited exports.")
    /// Failed to calculate progress
    public static let failedToCalculateProgress = Loc.tr("Errors", "failed_to_calculate_progress", fallback: "Failed to calculate progress")
    /// Failed to restore previous purchases
    public static let failedToRestorePreviousPurchases = Loc.tr("Errors", "failed_to_restore_previous_purchases", fallback: "Failed to restore previous purchases")
    /// Failed to save quiz session
    public static let failedToSaveQuizSession = Loc.tr("Errors", "failed_to_save_quiz_session", fallback: "Failed to save quiz session")
    /// Failed to update user statistics
    public static let failedToUpdateUserStatistics = Loc.tr("Errors", "failed_to_update_user_statistics", fallback: "Failed to update user statistics")
    /// Failed to update word difficulty level
    public static let failedToUpdateWordDifficultyLevel = Loc.tr("Errors", "failed_to_update_word_difficulty_level", fallback: "Failed to update word difficulty level")
    /// Failed to update word progress
    public static let failedToUpdateWordProgress = Loc.tr("Errors", "failed_to_update_word_progress", fallback: "Failed to update word progress")
    /// Import failed
    public static let importFailed = Loc.tr("Errors", "import_failed", fallback: "Import failed")
    /// Input cannot be empty
    public static let inputCannotBeEmpty = Loc.tr("Errors", "input_cannot_be_empty", fallback: "Input cannot be empty")
    /// Input is not a word
    public static let inputNotWord = Loc.tr("Errors", "input_not_word", fallback: "Input is not a word")
    /// Invalid input
    public static let invalidInput = Loc.tr("Errors", "invalid_input", fallback: "Invalid input")
    /// Invalid input provided
    public static let invalidInputProvided = Loc.tr("Errors", "invalid_input_provided", fallback: "Invalid input provided")
    /// Invalid response
    public static let invalidResponse = Loc.tr("Errors", "invalid_response", fallback: "Invalid response")
    /// Invalid response from translation service
    public static let invalidResponseFromTranslationService = Loc.tr("Errors", "invalid_response_from_translation_service", fallback: "Invalid response from translation service")
    /// Invalid translation URL
    public static let invalidTranslationUrl = Loc.tr("Errors", "invalid_translation_url", fallback: "Invalid translation URL")
    /// Invalid URL
    public static let invalidUrl = Loc.tr("Errors", "invalid_url", fallback: "Invalid URL")
    /// Invalid user email
    public static let invalidUserEmail = Loc.tr("Errors", "invalid_user_email", fallback: "Invalid user email")
    /// Invalid word ID
    public static let invalidWordId = Loc.tr("Errors", "invalid_word_id", fallback: "Invalid word ID")
    /// Maximum of 5 tags per word reached
    public static let maxTagsReached = Loc.tr("Errors", "max_tags_reached", fallback: "Maximum of 5 tags per word reached")
    /// Missing API key
    public static let missingApiKey = Loc.tr("Errors", "missing_api_key", fallback: "Missing API key")
    /// Missing field
    public static let missingField = Loc.tr("Errors", "missing_field", fallback: "Missing field")
    /// Network error during translation
    public static let networkErrorDuringTranslation = Loc.tr("Errors", "network_error_during_translation", fallback: "Network error during translation")
    /// Network error occurred
    public static let networkErrorOccurred = Loc.tr("Errors", "network_error_occurred", fallback: "Network error occurred")
    /// Timeout
    public static let networkTimeout = Loc.tr("Errors", "network_timeout", fallback: "Timeout")
    /// No active subscriptions found
    public static let noActiveSubscriptionsFound = Loc.tr("Errors", "no_active_subscriptions_found", fallback: "No active subscriptions found")
    /// No data
    public static let noData = Loc.tr("Errors", "no_data", fallback: "No data")
    /// No internet connection
    public static let noInternetConnection = Loc.tr("Errors", "no_internet_connection", fallback: "No internet connection")
    /// No subscription offerings are currently available
    public static let noOfferingsAvailable = Loc.tr("Errors", "no_offerings_available", fallback: "No subscription offerings are currently available")
    /// No subscription offerings are currently available
    public static let noSubscriptionOfferingsAvailable = Loc.tr("Errors", "no_subscription_offerings_available", fallback: "No subscription offerings are currently available")
    /// Ooops!
    public static let oops = Loc.tr("Errors", "oops", fallback: "Ooops!")
    /// The requested subscription package was not found
    public static let packageNotFound = Loc.tr("Errors", "package_not_found", fallback: "The requested subscription package was not found")
    /// You don't have permission to perform this action
    public static let permissionDenied = Loc.tr("Errors", "permission_denied", fallback: "You don't have permission to perform this action")
    /// The purchase could not be completed
    public static let purchaseCouldNotBeCompleted = Loc.tr("Errors", "purchase_could_not_be_completed", fallback: "The purchase could not be completed")
    /// The purchase could not be completed
    public static let purchaseFailed = Loc.tr("Errors", "purchase_failed", fallback: "The purchase could not be completed")
    /// Read failed
    public static let readFailed = Loc.tr("Errors", "read_failed", fallback: "Read failed")
    /// The requested subscription package was not found
    public static let requestedSubscriptionPackageNotFound = Loc.tr("Errors", "requested_subscription_package_not_found", fallback: "The requested subscription package was not found")
    /// Failed to restore previous purchases
    public static let restoreFailed = Loc.tr("Errors", "restore_failed", fallback: "Failed to restore previous purchases")
    /// Save failed
    public static let saveFailed = Loc.tr("Errors", "save_failed", fallback: "Save failed")
    /// Server unreachable
    public static let serverUnreachable = Loc.tr("Errors", "server_unreachable", fallback: "Server unreachable")
    /// Something went wrong
    public static let somethingWentWrong = Loc.tr("Errors", "something_went_wrong", fallback: "Something went wrong")
    /// Sync failed
    public static let syncFailed = Loc.tr("Errors", "sync_failed", fallback: "Sync failed")
    /// Tag is already assigned to this word
    public static let tagAlreadyAssigned = Loc.tr("Errors", "tag_already_assigned", fallback: "Tag is already assigned to this word")
    /// Tag is already assigned to this word
    public static let tagAlreadyAssignedToWord = Loc.tr("Errors", "tag_already_assigned_to_word", fallback: "Tag is already assigned to this word")
    /// Tag already exists
    public static let tagAlreadyExists = Loc.tr("Errors", "tag_already_exists", fallback: "Tag already exists")
    /// Tag is not assigned to this word
    public static let tagNotAssigned = Loc.tr("Errors", "tag_not_assigned", fallback: "Tag is not assigned to this word")
    /// Tag is not assigned to this word
    public static let tagNotAssignedToWord = Loc.tr("Errors", "tag_not_assigned_to_word", fallback: "Tag is not assigned to this word")
    /// Translation failed
    public static let translationFailed = Loc.tr("Errors", "translation_failed", fallback: "Translation failed")
    /// Unknown
    public static let unknown = Loc.tr("Errors", "unknown", fallback: "Unknown")
    /// Unknown error
    public static let unknownError = Loc.tr("Errors", "unknown_error", fallback: "Unknown error")
    /// Update failed
    public static let updateFailed = Loc.tr("Errors", "update_failed", fallback: "Update failed")
    /// User must be authenticated
    public static let userNotAuthenticated = Loc.tr("Errors", "user_not_authenticated", fallback: "User must be authenticated")
    /// Word not found
    public static let wordNotFound = Loc.tr("Errors", "word_not_found", fallback: "Word not found")
  }
  public enum FilterDisplay {
    /// Add tags to your words to organize them better
    public static let addTagsToOrganize = Loc.tr("FilterDisplay", "add_tags_to_organize", fallback: "Add tags to your words to organize them better")
    /// Add tags to your idioms to organize them better
    public static let addTagsToOrganizeIdioms = Loc.tr("FilterDisplay", "add_tags_to_organize_idioms", fallback: "Add tags to your idioms to organize them better")
    /// All
    public static let all = Loc.tr("FilterDisplay", "all", fallback: "All")
    /// Favorite
    public static let favorite = Loc.tr("FilterDisplay", "favorite", fallback: "Favorite")
    /// Idioms appear here as you practice them in quizzes
    public static let idiomsAppearHereAsYouPractice = Loc.tr("FilterDisplay", "idioms_appear_here_as_you_practice", fallback: "Idioms appear here as you practice them in quizzes")
    /// Idioms that need more practice will appear here
    public static let idiomsNeedMorePractice = Loc.tr("FilterDisplay", "idioms_need_more_practice", fallback: "Idioms that need more practice will appear here")
    /// In Progress
    public static let inProgress = Loc.tr("FilterDisplay", "in_progress", fallback: "In Progress")
    /// Language
    public static let language = Loc.tr("FilterDisplay", "language", fallback: "Language")
    /// Mastered
    public static let mastered = Loc.tr("FilterDisplay", "mastered", fallback: "Mastered")
    /// Needs Review
    public static let needsReview = Loc.tr("FilterDisplay", "needs_review", fallback: "Needs Review")
    /// New
    public static let new = Loc.tr("FilterDisplay", "new", fallback: "New")
    /// New idioms appear here when you add them to your list
    public static let newIdiomsAppearHere = Loc.tr("FilterDisplay", "new_idioms_appear_here", fallback: "New idioms appear here when you add them to your list")
    /// New words appear here when you add them to your list
    public static let newWordsAppearHere = Loc.tr("FilterDisplay", "new_words_appear_here", fallback: "New words appear here when you add them to your list")
    /// No Favorite Idioms
    public static let noFavoriteIdioms = Loc.tr("FilterDisplay", "no_favorite_idioms", fallback: "No Favorite Idioms")
    /// No Favorite Words
    public static let noFavoriteWords = Loc.tr("FilterDisplay", "no_favorite_words", fallback: "No Favorite Words")
    /// No Idioms In Progress
    public static let noIdiomsInProgress = Loc.tr("FilterDisplay", "no_idioms_in_progress", fallback: "No Idioms In Progress")
    /// No Idioms Need Review
    public static let noIdiomsNeedReview = Loc.tr("FilterDisplay", "no_idioms_need_review", fallback: "No Idioms Need Review")
    /// No idioms in this language
    public static let noIdiomsWithSelectedLanguage = Loc.tr("FilterDisplay", "no_idioms_with_selected_language", fallback: "No idioms in this language")
    /// Select a language when you add a idiom next time
    public static let noIdiomsWithSelectedLanguageDescription = Loc.tr("FilterDisplay", "no_idioms_with_selected_language_description", fallback: "Select a language when you add a idiom next time")
    /// No Idioms Yet
    public static let noIdiomsYet = Loc.tr("FilterDisplay", "no_idioms_yet", fallback: "No Idioms Yet")
    /// No Mastered Idioms
    public static let noMasteredIdioms = Loc.tr("FilterDisplay", "no_mastered_idioms", fallback: "No Mastered Idioms")
    /// No Mastered Words
    public static let noMasteredWords = Loc.tr("FilterDisplay", "no_mastered_words", fallback: "No Mastered Words")
    /// No New Idioms
    public static let noNewIdioms = Loc.tr("FilterDisplay", "no_new_idioms", fallback: "No New Idioms")
    /// No New Words
    public static let noNewWords = Loc.tr("FilterDisplay", "no_new_words", fallback: "No New Words")
    /// No Search Results
    public static let noSearchResults = Loc.tr("FilterDisplay", "no_search_results", fallback: "No Search Results")
    /// No Tagged Idioms
    public static let noTaggedIdioms = Loc.tr("FilterDisplay", "no_tagged_idioms", fallback: "No Tagged Idioms")
    /// No Tagged Words
    public static let noTaggedWords = Loc.tr("FilterDisplay", "no_tagged_words", fallback: "No Tagged Words")
    /// No Words In Progress
    public static let noWordsInProgress = Loc.tr("FilterDisplay", "no_words_in_progress", fallback: "No Words In Progress")
    /// No Words Need Review
    public static let noWordsNeedReview = Loc.tr("FilterDisplay", "no_words_need_review", fallback: "No Words Need Review")
    /// No words in this language
    public static let noWordsWithSelectedLanguage = Loc.tr("FilterDisplay", "no_words_with_selected_language", fallback: "No words in this language")
    /// Select a language when you add a word next time
    public static let noWordsWithSelectedLanguageDescription = Loc.tr("FilterDisplay", "no_words_with_selected_language_description", fallback: "Select a language when you add a word next time")
    /// No Words Yet
    public static let noWordsYet = Loc.tr("FilterDisplay", "no_words_yet", fallback: "No Words Yet")
    /// Search
    public static let search = Loc.tr("FilterDisplay", "search", fallback: "Search")
    /// Start building your vocabulary by adding your first word
    public static let startBuildingVocabulary = Loc.tr("FilterDisplay", "start_building_vocabulary", fallback: "Start building your vocabulary by adding your first word")
    /// Start building your vocabulary by adding your first idiom
    public static let startBuildingVocabularyIdioms = Loc.tr("FilterDisplay", "start_building_vocabulary_idioms", fallback: "Start building your vocabulary by adding your first idiom")
    /// Tag
    public static let tag = Loc.tr("FilterDisplay", "tag", fallback: "Tag")
    /// Tap the heart icon on any word to add it to your favorites
    public static let tapHeartIconToAddFavorites = Loc.tr("FilterDisplay", "tap_heart_icon_to_add_favorites", fallback: "Tap the heart icon on any word to add it to your favorites")
    /// Tap the heart icon on any idiom to add it to your favorites
    public static let tapHeartIconToAddFavoritesIdioms = Loc.tr("FilterDisplay", "tap_heart_icon_to_add_favorites_idioms", fallback: "Tap the heart icon on any idiom to add it to your favorites")
    /// Try a different search term or add a new word
    public static let tryDifferentSearchTerm = Loc.tr("FilterDisplay", "try_different_search_term", fallback: "Try a different search term or add a new word")
    /// Try a different search term or add a new idiom
    public static let tryDifferentSearchTermIdioms = Loc.tr("FilterDisplay", "try_different_search_term_idioms", fallback: "Try a different search term or add a new idiom")
    /// Words appear here as you practice them in quizzes
    public static let wordsAppearHereAsYouPractice = Loc.tr("FilterDisplay", "words_appear_here_as_you_practice", fallback: "Words appear here as you practice them in quizzes")
    /// Words that need more practice will appear here
    public static let wordsNeedMorePractice = Loc.tr("FilterDisplay", "words_need_more_practice", fallback: "Words that need more practice will appear here")
  }
  public enum Learning {
    public enum CommonActions {
      /// Back
      public static let back = Loc.tr("Learning", "common_actions.back", fallback: "Back")
      /// Continue
      public static let `continue` = Loc.tr("Learning", "common_actions.continue", fallback: "Continue")
      /// Done
      public static let done = Loc.tr("Learning", "common_actions.done", fallback: "Done")
      /// Finish
      public static let finish = Loc.tr("Learning", "common_actions.finish", fallback: "Finish")
      /// Next
      public static let next = Loc.tr("Learning", "common_actions.next", fallback: "Next")
      /// Skip
      public static let skip = Loc.tr("Learning", "common_actions.skip", fallback: "Skip")
    }
    public enum CurrentLevel {
      /// Help us understand where you're starting from
      public static let helpUsUnderstand = Loc.tr("Learning", "current_level.help_us_understand", fallback: "Help us understand where you're starting from")
      /// Select your current level
      public static let selectYourLevel = Loc.tr("Learning", "current_level.select_your_level", fallback: "Select your current level")
      /// What's your current level?
      public static let whatIsYourCurrentLevel = Loc.tr("Learning", "current_level.what_is_your_current_level", fallback: "What's your current level?")
    }
    public enum InterestCategory {
      /// Business
      public static let business = Loc.tr("Learning", "interest_category.business", fallback: "Business")
      /// Culture
      public static let culture = Loc.tr("Learning", "interest_category.culture", fallback: "Culture")
      /// Education
      public static let education = Loc.tr("Learning", "interest_category.education", fallback: "Education")
      /// Entertainment
      public static let entertainment = Loc.tr("Learning", "interest_category.entertainment", fallback: "Entertainment")
      /// Food
      public static let food = Loc.tr("Learning", "interest_category.food", fallback: "Food")
      /// Health
      public static let health = Loc.tr("Learning", "interest_category.health", fallback: "Health")
      /// Lifestyle
      public static let lifestyle = Loc.tr("Learning", "interest_category.lifestyle", fallback: "Lifestyle")
      /// Sports
      public static let sports = Loc.tr("Learning", "interest_category.sports", fallback: "Sports")
      /// Technology
      public static let technology = Loc.tr("Learning", "interest_category.technology", fallback: "Technology")
      /// Travel
      public static let travel = Loc.tr("Learning", "interest_category.travel", fallback: "Travel")
    }
    public enum Interests {
      /// Adventure
      public static let adventure = Loc.tr("Learning", "interests.adventure", fallback: "Adventure")
      /// Art
      public static let art = Loc.tr("Learning", "interests.art", fallback: "Art")
      /// Baking
      public static let baking = Loc.tr("Learning", "interests.baking", fallback: "Baking")
      /// Basketball
      public static let basketball = Loc.tr("Learning", "interests.basketball", fallback: "Basketball")
      /// Beauty
      public static let beauty = Loc.tr("Learning", "interests.beauty", fallback: "Beauty")
      /// Books
      public static let books = Loc.tr("Learning", "interests.books", fallback: "Books")
      /// Business
      public static let business = Loc.tr("Learning", "interests.business", fallback: "Business")
      /// Coffee
      public static let coffee = Loc.tr("Learning", "interests.coffee", fallback: "Coffee")
      /// Cooking
      public static let cooking = Loc.tr("Learning", "interests.cooking", fallback: "Cooking")
      /// Culture
      public static let culture = Loc.tr("Learning", "interests.culture", fallback: "Culture")
      /// Entrepreneurship
      public static let entrepreneurship = Loc.tr("Learning", "interests.entrepreneurship", fallback: "Entrepreneurship")
      /// Fashion
      public static let fashion = Loc.tr("Learning", "interests.fashion", fallback: "Fashion")
      /// Finance
      public static let finance = Loc.tr("Learning", "interests.finance", fallback: "Finance")
      /// Fitness
      public static let fitness = Loc.tr("Learning", "interests.fitness", fallback: "Fitness")
      /// Gaming
      public static let gaming = Loc.tr("Learning", "interests.gaming", fallback: "Gaming")
      /// Help us make your lessons more engaging by selecting topics you love
      public static let helpUsMakeLessonsEngaging = Loc.tr("Learning", "interests.help_us_make_lessons_engaging", fallback: "Help us make your lessons more engaging by selecting topics you love")
      /// History
      public static let history = Loc.tr("Learning", "interests.history", fallback: "History")
      /// Home & Decor
      public static let home = Loc.tr("Learning", "interests.home", fallback: "Home & Decor")
      /// Lifestyle
      public static let lifestyle = Loc.tr("Learning", "interests.lifestyle", fallback: "Lifestyle")
      /// Literature
      public static let literature = Loc.tr("Learning", "interests.literature", fallback: "Literature")
      /// Marketing
      public static let marketing = Loc.tr("Learning", "interests.marketing", fallback: "Marketing")
      /// Medicine
      public static let medicine = Loc.tr("Learning", "interests.medicine", fallback: "Medicine")
      /// Mental Health
      public static let mentalHealth = Loc.tr("Learning", "interests.mental_health", fallback: "Mental Health")
      /// Movies
      public static let movies = Loc.tr("Learning", "interests.movies", fallback: "Movies")
      /// Music
      public static let music = Loc.tr("Learning", "interests.music", fallback: "Music")
      /// Nutrition
      public static let nutrition = Loc.tr("Learning", "interests.nutrition", fallback: "Nutrition")
      /// Philosophy
      public static let philosophy = Loc.tr("Learning", "interests.philosophy", fallback: "Philosophy")
      /// Photography
      public static let photography = Loc.tr("Learning", "interests.photography", fallback: "Photography")
      /// Programming
      public static let programming = Loc.tr("Learning", "interests.programming", fallback: "Programming")
      /// Science
      public static let science = Loc.tr("Learning", "interests.science", fallback: "Science")
      /// Select your interests (optional)
      public static let selectInterests = Loc.tr("Learning", "interests.select_interests", fallback: "Select your interests (optional)")
      /// Soccer
      public static let soccer = Loc.tr("Learning", "interests.soccer", fallback: "Soccer")
      /// Social Media
      public static let socialMedia = Loc.tr("Learning", "interests.social_media", fallback: "Social Media")
      /// Swimming
      public static let swimming = Loc.tr("Learning", "interests.swimming", fallback: "Swimming")
      /// Technology
      public static let technology = Loc.tr("Learning", "interests.technology", fallback: "Technology")
      /// Tennis
      public static let tennis = Loc.tr("Learning", "interests.tennis", fallback: "Tennis")
      /// Travel
      public static let travel = Loc.tr("Learning", "interests.travel", fallback: "Travel")
      /// What interests you?
      public static let whatInterestsYou = Loc.tr("Learning", "interests.what_interests_you", fallback: "What interests you?")
      /// Wine
      public static let wine = Loc.tr("Learning", "interests.wine", fallback: "Wine")
    }
    public enum LanguageLevel {
      /// Advanced
      public static let advanced = Loc.tr("Learning", "language_level.advanced", fallback: "Advanced")
      /// I can express myself fluently in most situations
      public static let advancedDescription = Loc.tr("Learning", "language_level.advanced_description", fallback: "I can express myself fluently in most situations")
      /// Beginner
      public static let beginner = Loc.tr("Learning", "language_level.beginner", fallback: "Beginner")
      /// I know a few words or phrases
      public static let beginnerDescription = Loc.tr("Learning", "language_level.beginner_description", fallback: "I know a few words or phrases")
      /// Elementary
      public static let elementary = Loc.tr("Learning", "language_level.elementary", fallback: "Elementary")
      /// I can understand and use simple phrases
      public static let elementaryDescription = Loc.tr("Learning", "language_level.elementary_description", fallback: "I can understand and use simple phrases")
      /// Intermediate
      public static let intermediate = Loc.tr("Learning", "language_level.intermediate", fallback: "Intermediate")
      /// I can have conversations on familiar topics
      public static let intermediateDescription = Loc.tr("Learning", "language_level.intermediate_description", fallback: "I can have conversations on familiar topics")
      /// Native
      public static let native = Loc.tr("Learning", "language_level.native", fallback: "Native")
      /// I speak this language fluently
      public static let nativeDescription = Loc.tr("Learning", "language_level.native_description", fallback: "I speak this language fluently")
      /// Upper Intermediate
      public static let upperIntermediate = Loc.tr("Learning", "language_level.upper_intermediate", fallback: "Upper Intermediate")
      /// I can discuss complex topics with some difficulty
      public static let upperIntermediateDescription = Loc.tr("Learning", "language_level.upper_intermediate_description", fallback: "I can discuss complex topics with some difficulty")
    }
    public enum LearningGoals {
      /// Business
      public static let business = Loc.tr("Learning", "learning_goals.business", fallback: "Business")
      /// I need this for business communication
      public static let businessDescription = Loc.tr("Learning", "learning_goals.business_description", fallback: "I need this for business communication")
      /// Culture
      public static let culture = Loc.tr("Learning", "learning_goals.culture", fallback: "Culture")
      /// I'm interested in the culture and traditions
      public static let cultureDescription = Loc.tr("Learning", "learning_goals.culture_description", fallback: "I'm interested in the culture and traditions")
      /// Exam
      public static let exam = Loc.tr("Learning", "learning_goals.exam", fallback: "Exam")
      /// I'm preparing for a language exam
      public static let examDescription = Loc.tr("Learning", "learning_goals.exam_description", fallback: "I'm preparing for a language exam")
      /// Family
      public static let family = Loc.tr("Learning", "learning_goals.family", fallback: "Family")
      /// I want to communicate with family members
      public static let familyDescription = Loc.tr("Learning", "learning_goals.family_description", fallback: "I want to communicate with family members")
      /// Help us customize your course to match your objectives
      public static let helpUsCustomizeYourCourse = Loc.tr("Learning", "learning_goals.help_us_customize_your_course", fallback: "Help us customize your course to match your objectives")
      /// Hobby
      public static let hobby = Loc.tr("Learning", "learning_goals.hobby", fallback: "Hobby")
      /// I'm learning as a hobby
      public static let hobbyDescription = Loc.tr("Learning", "learning_goals.hobby_description", fallback: "I'm learning as a hobby")
      /// Migration
      public static let migration = Loc.tr("Learning", "learning_goals.migration", fallback: "Migration")
      /// I'm planning to move to a country where this language is spoken
      public static let migrationDescription = Loc.tr("Learning", "learning_goals.migration_description", fallback: "I'm planning to move to a country where this language is spoken")
      /// Personal
      public static let personal = Loc.tr("Learning", "learning_goals.personal", fallback: "Personal")
      /// I'm learning for personal interest
      public static let personalDescription = Loc.tr("Learning", "learning_goals.personal_description", fallback: "I'm learning for personal interest")
      /// Select your goals
      public static let selectGoals = Loc.tr("Learning", "learning_goals.select_goals", fallback: "Select your goals")
      /// Study
      public static let study = Loc.tr("Learning", "learning_goals.study", fallback: "Study")
      /// I need this language for academic purposes
      public static let studyDescription = Loc.tr("Learning", "learning_goals.study_description", fallback: "I need this language for academic purposes")
      /// Travel
      public static let travel = Loc.tr("Learning", "learning_goals.travel", fallback: "Travel")
      /// I want to communicate while traveling
      public static let travelDescription = Loc.tr("Learning", "learning_goals.travel_description", fallback: "I want to communicate while traveling")
      /// What are your learning goals?
      public static let whatAreYourGoals = Loc.tr("Learning", "learning_goals.what_are_your_goals", fallback: "What are your learning goals?")
      /// Work
      public static let work = Loc.tr("Learning", "learning_goals.work", fallback: "Work")
      /// I need this language for my career
      public static let workDescription = Loc.tr("Learning", "learning_goals.work_description", fallback: "I need this language for my career")
    }
    public enum LearningStyle {
      /// Auditory
      public static let auditory = Loc.tr("Learning", "learning_style.auditory", fallback: "Auditory")
      /// I learn best by listening and speaking
      public static let auditoryDescription = Loc.tr("Learning", "learning_style.auditory_description", fallback: "I learn best by listening and speaking")
      /// Balanced
      public static let balanced = Loc.tr("Learning", "learning_style.balanced", fallback: "Balanced")
      /// I enjoy a mix of different learning methods
      public static let balancedDescription = Loc.tr("Learning", "learning_style.balanced_description", fallback: "I enjoy a mix of different learning methods")
      /// Help us adapt the learning experience to your preferences
      public static let helpUsAdaptToYou = Loc.tr("Learning", "learning_style.help_us_adapt_to_you", fallback: "Help us adapt the learning experience to your preferences")
      /// Kinesthetic
      public static let kinesthetic = Loc.tr("Learning", "learning_style.kinesthetic", fallback: "Kinesthetic")
      /// I learn best through hands-on activities
      public static let kinestheticDescription = Loc.tr("Learning", "learning_style.kinesthetic_description", fallback: "I learn best through hands-on activities")
      /// Reading
      public static let reading = Loc.tr("Learning", "learning_style.reading", fallback: "Reading")
      /// I learn best through reading and writing
      public static let readingDescription = Loc.tr("Learning", "learning_style.reading_description", fallback: "I learn best through reading and writing")
      /// Select your learning style
      public static let selectLearningStyle = Loc.tr("Learning", "learning_style.select_learning_style", fallback: "Select your learning style")
      /// Visual
      public static let visual = Loc.tr("Learning", "learning_style.visual", fallback: "Visual")
      /// I learn best with images, charts, and visual content
      public static let visualDescription = Loc.tr("Learning", "learning_style.visual_description", fallback: "I learn best with images, charts, and visual content")
      /// What's your learning style?
      public static let whatIsYourLearningStyle = Loc.tr("Learning", "learning_style.what_is_your_learning_style", fallback: "What's your learning style?")
    }
    public enum Motivation {
      /// Academic Success
      public static let academic = Loc.tr("Learning", "motivation.academic", fallback: "Academic Success")
      /// I need this for my studies
      public static let academicDescription = Loc.tr("Learning", "motivation.academic_description", fallback: "I need this for my studies")
      /// Challenge
      public static let challenge = Loc.tr("Learning", "motivation.challenge", fallback: "Challenge")
      /// I love challenging myself
      public static let challengeDescription = Loc.tr("Learning", "motivation.challenge_description", fallback: "I love challenging myself")
      /// Cultural Understanding
      public static let cultural = Loc.tr("Learning", "motivation.cultural", fallback: "Cultural Understanding")
      /// I want to understand different cultures
      public static let culturalDescription = Loc.tr("Learning", "motivation.cultural_description", fallback: "I want to understand different cultures")
      /// Help us keep you motivated throughout your journey
      public static let helpUsKeepYouMotivated = Loc.tr("Learning", "motivation.help_us_keep_you_motivated", fallback: "Help us keep you motivated throughout your journey")
      /// Personal Growth
      public static let personal = Loc.tr("Learning", "motivation.personal", fallback: "Personal Growth")
      /// I want to grow as a person
      public static let personalDescription = Loc.tr("Learning", "motivation.personal_description", fallback: "I want to grow as a person")
      /// Professional Development
      public static let professional = Loc.tr("Learning", "motivation.professional", fallback: "Professional Development")
      /// I want to advance my career
      public static let professionalDescription = Loc.tr("Learning", "motivation.professional_description", fallback: "I want to advance my career")
      /// Select your motivation
      public static let selectMotivation = Loc.tr("Learning", "motivation.select_motivation", fallback: "Select your motivation")
      /// Social Connection
      public static let social = Loc.tr("Learning", "motivation.social", fallback: "Social Connection")
      /// I want to connect with more people
      public static let socialDescription = Loc.tr("Learning", "motivation.social_description", fallback: "I want to connect with more people")
      /// What motivates you to learn?
      public static let whatMotivatesYou = Loc.tr("Learning", "motivation.what_motivates_you", fallback: "What motivates you to learn?")
    }
    public enum NativeLanguage {
      /// Help us explain things in a way you'll understand best
      public static let helpUsExplainThings = Loc.tr("Learning", "native_language.help_us_explain_things", fallback: "Help us explain things in a way you'll understand best")
      /// Select your native language
      public static let selectNativeLanguage = Loc.tr("Learning", "native_language.select_native_language", fallback: "Select your native language")
      /// What's your native language?
      public static let whatIsYourNativeLanguage = Loc.tr("Learning", "native_language.what_is_your_native_language", fallback: "What's your native language?")
    }
    public enum Onboarding {
      /// Get Started
      public static let getStarted = Loc.tr("Learning", "onboarding.get_started", fallback: "Get Started")
      /// Let's get to know you better to create the perfect learning experience
      public static let letUsGetToKnowYou = Loc.tr("Learning", "onboarding.let_us_get_to_know_you", fallback: "Let's get to know you better to create the perfect learning experience")
      /// Your personalized language course
      public static let personalizedLanguageCourse = Loc.tr("Learning", "onboarding.personalized_language_course", fallback: "Your personalized language course")
      /// Welcome to Learning
      public static let welcomeToLearning = Loc.tr("Learning", "onboarding.welcome_to_learning", fallback: "Welcome to Learning")
    }
    public enum Progress {
      /// Progress
      public static let progress = Loc.tr("Learning", "progress.progress", fallback: "Progress")
      /// Step %d of %d
      public static func stepOf(_ p1: Int, _ p2: Int) -> String {
        return Loc.tr("Learning", "progress.step_of", p1, p2, fallback: "Step %d of %d")
      }
    }
    public enum Summary {
      /// Here's what we learned about you
      public static let hereIsWhatWeLearned = Loc.tr("Learning", "summary.here_is_what_we_learned", fallback: "Here's what we learned about you")
      /// Let's begin your personalized learning journey
      public static let letSBeginYourJourney = Loc.tr("Learning", "summary.let_s_begin_your_journey", fallback: "Let's begin your personalized learning journey")
      /// Ready to Start Learning
      public static let readyToStart = Loc.tr("Learning", "summary.ready_to_start", fallback: "Ready to Start Learning")
      /// Your Learning Profile
      public static let yourLearningProfile = Loc.tr("Learning", "summary.your_learning_profile", fallback: "Your Learning Profile")
    }
    public enum Tabbar {
      /// Learn
      public static let learn = Loc.tr("Learning", "tabbar.learn", fallback: "Learn")
    }
    public enum TargetLanguage {
      /// Choose Your Target Language
      public static let chooseTargetLanguage = Loc.tr("Learning", "target_language.choose_target_language", fallback: "Choose Your Target Language")
      /// This will be the language we'll teach you
      public static let thisWillBeTheLanguage = Loc.tr("Learning", "target_language.this_will_be_the_language", fallback: "This will be the language we'll teach you")
      /// Which language do you want to learn?
      public static let whichLanguageDoYouWantToLearn = Loc.tr("Learning", "target_language.which_language_do_you_want_to_learn", fallback: "Which language do you want to learn?")
    }
    public enum TimeCommitment {
      /// Casual
      public static let casual = Loc.tr("Learning", "time_commitment.casual", fallback: "Casual")
      /// 10 minutes per day - perfect for busy schedules
      public static let casualDescription = Loc.tr("Learning", "time_commitment.casual_description", fallback: "10 minutes per day - perfect for busy schedules")
      /// Help us plan your learning schedule
      public static let helpUsPlanYourSchedule = Loc.tr("Learning", "time_commitment.help_us_plan_your_schedule", fallback: "Help us plan your learning schedule")
      /// How much time can you commit?
      public static let howMuchTime = Loc.tr("Learning", "time_commitment.how_much_time", fallback: "How much time can you commit?")
      /// Intensive
      public static let intensive = Loc.tr("Learning", "time_commitment.intensive", fallback: "Intensive")
      /// 45 minutes per day - fast progress
      public static let intensiveDescription = Loc.tr("Learning", "time_commitment.intensive_description", fallback: "45 minutes per day - fast progress")
      /// Intensive+
      public static let intensivePlus = Loc.tr("Learning", "time_commitment.intensive_plus", fallback: "Intensive+")
      /// 90+ minutes per day - maximum progress
      public static let intensivePlusDescription = Loc.tr("Learning", "time_commitment.intensive_plus_description", fallback: "90+ minutes per day - maximum progress")
      /// Regular
      public static let regular = Loc.tr("Learning", "time_commitment.regular", fallback: "Regular")
      /// 20 minutes per day - steady progress
      public static let regularDescription = Loc.tr("Learning", "time_commitment.regular_description", fallback: "20 minutes per day - steady progress")
      /// Select your time commitment
      public static let selectTimeCommitment = Loc.tr("Learning", "time_commitment.select_time_commitment", fallback: "Select your time commitment")
    }
  }
  public enum Migration {
    /// Your data is being safely upgraded and will remain intact
    public static let dataSafeUpgradeMessage = Loc.tr("Migration", "data_safe_upgrade_message", fallback: "Your data is being safely upgraded and will remain intact")
    /// We're enhancing your vocabulary with new features
    public static let enhancingVocabularyMessage = Loc.tr("Migration", "enhancing_vocabulary_message", fallback: "We're enhancing your vocabulary with new features")
    /// Migration Error
    public static let migrationError = Loc.tr("Migration", "migration_error", fallback: "Migration Error")
    /// Migration failed: %@
    /// 
    /// Would you like to retry?
    public static func migrationFailedMessage(_ p1: Any) -> String {
      return Loc.tr("Migration", "migration_failed_message", String(describing: p1), fallback: "Migration failed: %@\n\nWould you like to retry?")
    }
    /// Please don't close the app during this process
    public static let pleaseDontCloseApp = Loc.tr("Migration", "please_dont_close_app", fallback: "Please don't close the app during this process")
    /// Updating Your Dictionary
    public static let updatingYourDictionary = Loc.tr("Migration", "updating_your_dictionary", fallback: "Updating Your Dictionary")
  }
  public enum Navigation {
    /// About
    public static let about = Loc.tr("Navigation", "about", fallback: "About")
    /// Add Tags
    public static let addTags = Loc.tr("Navigation", "add_tags", fallback: "Add Tags")
    /// Close
    public static let close = Loc.tr("Navigation", "close", fallback: "Close")
    /// Close screen
    public static let closeScreen = Loc.tr("Navigation", "close_screen", fallback: "Close screen")
    /// Context Usage Quiz
    public static let contextMultipleChoiceQuiz = Loc.tr("Navigation", "context_multiple_choice_quiz", fallback: "Context Usage Quiz")
    /// Debug Panel
    public static let debugPanel = Loc.tr("Navigation", "debug_panel", fallback: "Debug Panel")
    /// Definition Quiz
    public static let definitionQuiz = Loc.tr("Navigation", "definition_quiz", fallback: "Definition Quiz")
    /// Fill in the Blank Quiz
    public static let fillInTheBlankQuiz = Loc.tr("Navigation", "fill_in_the_blank_quiz", fallback: "Fill in the Blank Quiz")
    /// Idiom Details
    public static let idiomDetails = Loc.tr("Navigation", "idiom_details", fallback: "Idiom Details")
    /// Quiz Results
    public static let quizResults = Loc.tr("Navigation", "quiz_results", fallback: "Quiz Results")
    /// Sentence Writing Quiz
    public static let sentenceWritingQuiz = Loc.tr("Navigation", "sentence_writing_quiz", fallback: "Sentence Writing Quiz")
    /// Spelling Quiz
    public static let spellingQuiz = Loc.tr("Navigation", "spelling_quiz", fallback: "Spelling Quiz")
    /// Word Details
    public static let wordDetails = Loc.tr("Navigation", "word_details", fallback: "Word Details")
    public enum Tabbar {
      /// Learn
      public static let learn = Loc.tr("Navigation", "tabbar.learn", fallback: "Learn")
      /// Progress
      public static let progress = Loc.tr("Navigation", "tabbar.progress", fallback: "Progress")
      /// Quizzes
      public static let quizzes = Loc.tr("Navigation", "tabbar.quizzes", fallback: "Quizzes")
      /// Settings
      public static let settings = Loc.tr("Navigation", "tabbar.settings", fallback: "Settings")
    }
  }
  public enum Notifications {
    /// You have words that need more practice. Ready for a challenge?
    public static let difficultWordsChallenge = Loc.tr("Notifications", "difficult_words_challenge", fallback: "You have words that need more practice. Ready for a challenge?")
    /// To receive daily reminders and difficult word alerts, please enable notifications in Settings.
    public static let permissionDeniedMessage = Loc.tr("Notifications", "permission_denied_message", fallback: "To receive daily reminders and difficult word alerts, please enable notifications in Settings.")
    /// Notification Permission Required
    public static let permissionRequired = Loc.tr("Notifications", "permission_required", fallback: "Notification Permission Required")
    /// Practice Your Difficult Words 📚
    public static let practiceDifficultWords = Loc.tr("Notifications", "practice_difficult_words", fallback: "Practice Your Difficult Words 📚")
    /// Don't forget to practice your vocabulary today.
    public static let practiceVocabularyToday = Loc.tr("Notifications", "practice_vocabulary_today", fallback: "Don't forget to practice your vocabulary today.")
    /// Test Dictionary Invitation
    public static let testDictionaryInvitation = Loc.tr("Notifications", "test_dictionary_invitation", fallback: "Test Dictionary Invitation")
    /// Someone added you to 'Test Dictionary'
    public static let testDictionaryInvitationBody = Loc.tr("Notifications", "test_dictionary_invitation_body", fallback: "Someone added you to 'Test Dictionary'")
    /// Time to Practice! 📚
    public static let timeToPractice = Loc.tr("Notifications", "time_to_practice", fallback: "Time to Practice! 📚")
  }
  public enum Onboarding {
    /// Adaptive quizzes that learn from your progress
    public static let adaptiveQuizzes = Loc.tr("Onboarding", "adaptive_quizzes", fallback: "Adaptive quizzes that learn from your progress")
    /// Back
    public static let back = Loc.tr("Onboarding", "back", fallback: "Back")
    /// Build Your Vocabulary
    public static let buildYourVocabulary = Loc.tr("Onboarding", "build_your_vocabulary", fallback: "Build Your Vocabulary")
    /// Collaborative Learning
    public static let collaborativeLearning = Loc.tr("Onboarding", "collaborative_learning", fallback: "Collaborative Learning")
    /// Share dictionaries with friends and family
    public static let collaborativeLearningDescription = Loc.tr("Onboarding", "collaborative_learning_description", fallback: "Share dictionaries with friends and family")
    /// Collect Idioms
    public static let collectIdioms = Loc.tr("Onboarding", "collect_idioms", fallback: "Collect Idioms")
    /// Learn and practice idioms and expressions from around the world
    public static let collectIdiomsDescription = Loc.tr("Onboarding", "collect_idioms_description", fallback: "Learn and practice idioms and expressions from around the world")
    /// Get comprehensive definitions with multiple meanings and contexts
    public static let comprehensiveDefinitions = Loc.tr("Onboarding", "comprehensive_definitions", fallback: "Get comprehensive definitions with multiple meanings and contexts")
    /// Create and organize your own vocabulary collections with custom definitions and examples
    public static let createOrganizeVocabulary = Loc.tr("Onboarding", "create_organize_vocabulary", fallback: "Create and organize your own vocabulary collections with custom definitions and examples")
    /// Find Definitions
    public static let findDefinitions = Loc.tr("Onboarding", "find_definitions", fallback: "Find Definitions")
    /// Get comprehensive definitions with multiple meanings and contexts
    public static let findDefinitionsDescription = Loc.tr("Onboarding", "find_definitions_description", fallback: "Get comprehensive definitions with multiple meanings and contexts")
    /// Get Started
    public static let getStarted = Loc.tr("Onboarding", "get_started", fallback: "Get Started")
    /// Learn and practice idioms and expressions from around the world
    public static let learnPracticeIdioms = Loc.tr("Onboarding", "learn_practice_idioms", fallback: "Learn and practice idioms and expressions from around the world")
    /// My Dictionary
    public static let myDictionary = Loc.tr("Onboarding", "my_dictionary", fallback: "My Dictionary")
    /// Natural Voices
    public static let naturalVoices = Loc.tr("Onboarding", "natural_voices", fallback: "Natural Voices")
    /// Hundreds of premium voices that sound more human than ever
    public static let naturalVoicesDescription = Loc.tr("Onboarding", "natural_voices_description", fallback: "Hundreds of premium voices that sound more human than ever")
    /// Next
    public static let next = Loc.tr("Onboarding", "next", fallback: "Next")
    /// Next
    public static let nextStep = Loc.tr("Onboarding", "next_step", fallback: "Next")
    /// Your personal vocabulary companion
    public static let personalVocabularyCompanion = Loc.tr("Onboarding", "personal_vocabulary_companion", fallback: "Your personal vocabulary companion")
    /// Personal Word List
    public static let personalWordList = Loc.tr("Onboarding", "personal_word_list", fallback: "Personal Word List")
    /// Create and organize your own vocabulary collections with custom definitions and examples
    public static let personalWordListDescription = Loc.tr("Onboarding", "personal_word_list_description", fallback: "Create and organize your own vocabulary collections with custom definitions and examples")
    /// Personalized Learning
    public static let personalizedLearning = Loc.tr("Onboarding", "personalized_learning", fallback: "Personalized Learning")
    /// Progress Tracking
    public static let progressTracking = Loc.tr("Onboarding", "progress_tracking", fallback: "Progress Tracking")
    /// Visual insights into your vocabulary growth
    public static let progressTrackingDescription = Loc.tr("Onboarding", "progress_tracking_description", fallback: "Visual insights into your vocabulary growth")
    /// Share dictionaries with friends and family
    public static let shareDictionaries = Loc.tr("Onboarding", "share_dictionaries", fallback: "Share dictionaries with friends and family")
    /// Smart Quizzes
    public static let smartQuizzes = Loc.tr("Onboarding", "smart_quizzes", fallback: "Smart Quizzes")
    /// Adaptive quizzes that learn from your progress
    public static let smartQuizzesDescription = Loc.tr("Onboarding", "smart_quizzes_description", fallback: "Adaptive quizzes that learn from your progress")
    /// Start building your vocabulary today and watch your language skills grow.
    public static let startBuildingVocabulary = Loc.tr("Onboarding", "start_building_vocabulary", fallback: "Start building your vocabulary today and watch your language skills grow.")
    /// Visual insights into your vocabulary growth
    public static let visualInsights = Loc.tr("Onboarding", "visual_insights", fallback: "Visual insights into your vocabulary growth")
    /// Welcome to
    public static let welcomeTo = Loc.tr("Onboarding", "welcome_to", fallback: "Welcome to")
    /// You're All Set!
    public static let youreAllSet = Loc.tr("Onboarding", "youre_all_set", fallback: "You're All Set!")
  }
  public enum Plurals {
    public enum Analytics {
      /// Plural format key: "%#@COUNT@"
      public static func pointsCount(_ p1: Int) -> String {
        return Loc.tr("Plurals", "analytics.points_count", p1, fallback: "Plural format key: \"%#@COUNT@\"")
      }
      /// Plural format key: "You have completed %#@COUNT@ this month."
      public static func quizzesCompletedThisMonth(_ p1: Int) -> String {
        return Loc.tr("Plurals", "analytics.quizzes_completed_this_month", p1, fallback: "Plural format key: \"You have completed %#@COUNT@ this month.\"")
      }
      /// Plural format key: "%#@COUNT@"
      public static func quizzesCount(_ p1: Int) -> String {
        return Loc.tr("Plurals", "analytics.quizzes_count", p1, fallback: "Plural format key: \"%#@COUNT@\"")
      }
    }
    public enum Idioms {
      /// Plural format key: "%#@COUNT@"
      public static func idiomsCount(_ p1: Int) -> String {
        return Loc.tr("Plurals", "idioms.idioms_count", p1, fallback: "Plural format key: \"%#@COUNT@\"")
      }
    }
    public enum SharedDictionaries {
      /// Plural format key: "%#@COUNT@"
      public static func collaborators(_ p1: Int) -> String {
        return Loc.tr("Plurals", "shared_dictionaries.collaborators", p1, fallback: "Plural format key: \"%#@COUNT@\"")
      }
      /// Plural format key: "%#@COUNT@ of 1 dictionary created"
      public static func dictionaryCountCreated(_ p1: Int) -> String {
        return Loc.tr("Plurals", "shared_dictionaries.dictionary_count_created", p1, fallback: "Plural format key: \"%#@COUNT@ of 1 dictionary created\"")
      }
    }
    public enum Words {
      /// Plural format key: "%#@COUNT@"
      public static func wordsCount(_ p1: Int) -> String {
        return Loc.tr("Plurals", "words.words_count", p1, fallback: "Plural format key: \"%#@COUNT@\"")
      }
    }
  }
  public enum Quizzes {
    /// Accuracy
    public static let accuracy = Loc.tr("Quizzes", "accuracy", fallback: "Accuracy")
    /// Add More Words
    public static let addMoreWords = Loc.tr("Quizzes", "add_more_words", fallback: "Add More Words")
    /// Add Words to Shared Dictionary
    public static let addWordsToSharedDictionary = Loc.tr("Quizzes", "add_words_to_shared_dictionary", fallback: "Add Words to Shared Dictionary")
    /// Add Your First Word
    public static let addYourFirstWord = Loc.tr("Quizzes", "add_your_first_word", fallback: "Add Your First Word")
    /// All Results
    public static let allResults = Loc.tr("Quizzes", "all_results", fallback: "All Results")
    /// Ask the dictionary owner to add more words, or switch to a different dictionary!
    public static let askDictionaryOwnerAddWords = Loc.tr("Quizzes", "ask_dictionary_owner_add_words", fallback: "Ask the dictionary owner to add more words, or switch to a different dictionary!")
    /// Ask the dictionary owner to add more words, or switch to a different dictionary!
    public static let askDictionaryOwnerAddWordsOrSwitch = Loc.tr("Quizzes", "ask_dictionary_owner_add_words_or_switch", fallback: "Ask the dictionary owner to add more words, or switch to a different dictionary!")
    /// Attempt
    public static let attempt = Loc.tr("Quizzes", "attempt", fallback: "Attempt")
    /// Back to Quizzes
    public static let backToQuizzes = Loc.tr("Quizzes", "back_to_quizzes", fallback: "Back to Quizzes")
    /// Best
    public static let best = Loc.tr("Quizzes", "best", fallback: "Best")
    /// Best: %d
    public static func bestFormat(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "best_format", p1, fallback: "Best: %d")
    }
    /// Best Streak
    public static let bestStreak = Loc.tr("Quizzes", "best_streak", fallback: "Best Streak")
    /// Choose the Correct Definition
    public static let chooseCorrectDefinition = Loc.tr("Quizzes", "choose_correct_definition", fallback: "Choose the Correct Definition")
    /// Configure your quiz experience
    public static let configureQuizExperience = Loc.tr("Quizzes", "configure_quiz_experience", fallback: "Configure your quiz experience")
    /// contributions
    public static let contributions = Loc.tr("Quizzes", "contributions", fallback: "contributions")
    /// Correct!
    public static let correct = Loc.tr("Quizzes", "correct", fallback: "Correct!")
    /// Correct Answers
    public static let correctAnswers = Loc.tr("Quizzes", "correct_answers", fallback: "Correct Answers")
    /// The correct word is '%@'. Moving to next word...
    public static func correctWordIs(_ p1: Any) -> String {
      return Loc.tr("Quizzes", "correct_word_is", String(describing: p1), fallback: "The correct word is '%@'. Moving to next word...")
    }
    /// Select the correct definition for each word
    public static let definitionQuizDescription = Loc.tr("Quizzes", "definition_quiz_description", fallback: "Select the correct definition for each word")
    /// Final Score
    public static let finalScore = Loc.tr("Quizzes", "final_score", fallback: "Final Score")
    /// Finish
    public static let finish = Loc.tr("Quizzes", "finish", fallback: "Finish")
    /// Focus on words that need review
    public static let focusWordsNeedReview = Loc.tr("Quizzes", "focus_words_need_review", fallback: "Focus on words that need review")
    /// Great job! You've completed the definition quiz.
    public static let greatJobCompletedDefinitionQuiz = Loc.tr("Quizzes", "great_job_completed_definition_quiz", fallback: "Great job! You've completed the definition quiz.")
    /// Great job! You've completed the spelling quiz.
    public static let greatJobCompletedSpellingQuiz = Loc.tr("Quizzes", "great_job_completed_spelling_quiz", fallback: "Great job! You've completed the spelling quiz.")
    /// Hint
    public static let hint = Loc.tr("Quizzes", "hint", fallback: "Hint")
    /// Incorrect
    public static let incorrect = Loc.tr("Quizzes", "incorrect", fallback: "Incorrect")
    /// Incorrect! Moving to next question...
    public static let incorrectMovingToNextQuestion = Loc.tr("Quizzes", "incorrect_moving_to_next_question", fallback: "Incorrect! Moving to next question...")
    /// Keep Adding Words!
    public static let keepAddingWords = Loc.tr("Quizzes", "keep_adding_words", fallback: "Keep Adding Words!")
    /// Keep up the good work!
    public static let keepUpGoodWork = Loc.tr("Quizzes", "keep_up_good_work", fallback: "Keep up the good work!")
    /// %d
    public static func maxWords(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "max_words", p1, fallback: "%d")
    }
    /// %d
    public static func minWords(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "min_words", p1, fallback: "%d")
    }
    /// Moving to next question...
    public static let movingToNextQuestion = Loc.tr("Quizzes", "moving_to_next_question", fallback: "Moving to next question...")
    /// Moving to next word...
    public static let movingToNextWord = Loc.tr("Quizzes", "moving_to_next_word", fallback: "Moving to next word...")
    /// You need at least 1 hard word to practice in hard words mode. You currently have %d hard words.
    public static func needAtLeastHardWordPractice(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "need_at_least_hard_word_practice", p1, fallback: "You need at least 1 hard word to practice in hard words mode. You currently have %d hard words.")
    }
    /// Need at least %d words for the quiz.
    public static func needAtLeastWords(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "need_at_least_words", p1, fallback: "Need at least %d words for the quiz.")
    }
    /// You need at least 10 words to start quizzes. You currently have %d words.
    public static func needAtLeastWordsStartQuizzes(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "need_at_least_words_start_quizzes", p1, fallback: "You need at least 10 words to start quizzes. You currently have %d words.")
    }
    /// The shared dictionary '%@' needs at least 10 words to start quizzes. It currently has %d words.
    public static func needsAtLeastWordsStartQuizzes(_ p1: Any, _ p2: Int) -> String {
      return Loc.tr("Quizzes", "needs_at_least_words_start_quizzes", String(describing: p1), p2, fallback: "The shared dictionary '%@' needs at least 10 words to start quizzes. It currently has %d words.")
    }
    /// Next Word
    public static let nextWord = Loc.tr("Quizzes", "next_word", fallback: "Next Word")
    /// No difficult words available for quiz
    public static let noDifficultWordsAvailable = Loc.tr("Quizzes", "no_difficult_words_available", fallback: "No difficult words available for quiz")
    /// Not enough words available. Need at least %d words for the quiz.
    public static func notEnoughWordsAvailable(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "not_enough_words_available", p1, fallback: "Not enough words available. Need at least %d words for the quiz.")
    }
    /// Not enough words to review yet
    public static let notEnoughWordsReview = Loc.tr("Quizzes", "not_enough_words_review", fallback: "Not enough words to review yet")
    /// Number of words
    public static let numberWords = Loc.tr("Quizzes", "number_words", fallback: "Number of words")
    /// Number of words to practice in each session (%d-%d)
    public static func numberWordsPracticeSession(_ p1: Int, _ p2: Int) -> String {
      return Loc.tr("Quizzes", "number_words_practice_session", p1, p2, fallback: "Number of words to practice in each session (%d-%d)")
    }
    /// Practice Hard Words Only
    public static let practiceHardWordsOnly = Loc.tr("Quizzes", "practice_hard_words_only", fallback: "Practice Hard Words Only")
    /// Practice Settings
    public static let practiceSettings = Loc.tr("Quizzes", "practice_settings", fallback: "Practice Settings")
    /// Progress
    public static let progress = Loc.tr("Quizzes", "progress", fallback: "Progress")
    /// Progress: %d/%d
    public static func progressFormat(_ p1: Int, _ p2: Int) -> String {
      return Loc.tr("Quizzes", "progress_format", p1, p2, fallback: "Progress: %d/%d")
    }
    /// Sorry, quiz is only available once a day. Subscribe to PRO for unlimited access!
    public static let quizAvailableOnceADayMessage = Loc.tr("Quizzes", "quiz_available_once_a_day_message", fallback: "Sorry, quiz is only available once a day. Subscribe to PRO for unlimited access!")
    /// Quiz Complete!
    public static let quizComplete = Loc.tr("Quizzes", "quiz_complete", fallback: "Quiz Complete!")
    /// Quiz Types
    public static let quizTypes = Loc.tr("Quizzes", "quiz_types", fallback: "Quiz Types")
    /// Quiz Unavailable
    public static let quizUnavailable = Loc.tr("Quizzes", "quiz_unavailable", fallback: "Quiz Unavailable")
    /// Score
    public static let score = Loc.tr("Quizzes", "score", fallback: "Score")
    /// Score: %d
    public static func scoreFormat(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "score_format", p1, fallback: "Score: %d")
    }
    /// Select Dictionary
    public static let selectDictionary = Loc.tr("Quizzes", "select_dictionary", fallback: "Select Dictionary")
    /// Select a shared dictionary that is already populated with words.
    public static let selectSharedDictionaryPopulated = Loc.tr("Quizzes", "select_shared_dictionary_populated", fallback: "Select a shared dictionary that is already populated with words.")
    /// The shared dictionary '%@' needs at least 1 hard word to practice in hard words mode. It currently has %d hard words.
    public static func sharedDictionaryNeedsHardWords(_ p1: Any, _ p2: Int) -> String {
      return Loc.tr("Quizzes", "shared_dictionary_needs_hard_words", String(describing: p1), p2, fallback: "The shared dictionary '%@' needs at least 1 hard word to practice in hard words mode. It currently has %d hard words.")
    }
    /// Shared Dictionary Needs More Words!
    public static let sharedDictionaryNeedsMoreWords = Loc.tr("Quizzes", "shared_dictionary_needs_more_words", fallback: "Shared Dictionary Needs More Words!")
    /// Skip Word (-2 points)
    public static let skipWord = Loc.tr("Quizzes", "skip_word", fallback: "Skip Word (-2 points)")
    /// Test your spelling skills by typing words correctly
    public static let spellingQuizDescription = Loc.tr("Quizzes", "spelling_quiz_description", fallback: "Test your spelling skills by typing words correctly")
    /// Start Building Your Vocabulary!
    public static let startBuildingVocabulary = Loc.tr("Quizzes", "start_building_vocabulary", fallback: "Start Building Your Vocabulary!")
    /// Streak
    public static let streak = Loc.tr("Quizzes", "streak", fallback: "Streak")
    /// 🔥 Streak: %d
    public static func streakFormat(_ p1: Int) -> String {
      return Loc.tr("Quizzes", "streak_format", p1, fallback: "🔥 Streak: %d")
    }
    /// Submit Answer
    public static let submitAnswer = Loc.tr("Quizzes", "submit_answer", fallback: "Submit Answer")
    /// Switch to a different dictionary!
    public static let switchDifferentDictionary = Loc.tr("Quizzes", "switch_different_dictionary", fallback: "Switch to a different dictionary!")
    /// Well done!
    public static let wellDone = Loc.tr("Quizzes", "well_done", fallback: "Well done!")
    /// Word
    public static let word = Loc.tr("Quizzes", "word", fallback: "Word")
    /// The word starts with
    public static let wordStartsWith = Loc.tr("Quizzes", "word_starts_with", fallback: "The word starts with")
    /// Words per Session
    public static let wordsPerSession = Loc.tr("Quizzes", "words_per_session", fallback: "Words per Session")
    /// You can practice your own vocabulary, or select a shared dictionary that is already populated with words.
    public static let youCanPracticeVocabulary = Loc.tr("Quizzes", "you_can_practice_vocabulary", fallback: "You can practice your own vocabulary, or select a shared dictionary that is already populated with words.")
    /// Your Answer
    public static let yourAnswer = Loc.tr("Quizzes", "your_answer", fallback: "Your Answer")
    /// Your Results
    public static let yourResults = Loc.tr("Quizzes", "your_results", fallback: "Your Results")
    public enum AiQuiz {
      /// Analysis complete
      public static let aiAnalysisComplete = Loc.tr("Quizzes", "ai_quiz.ai_analysis_complete", fallback: "Analysis complete")
      /// Context Feedback:
      public static let aiContextFeedback = Loc.tr("Quizzes", "ai_quiz.ai_context_feedback", fallback: "Context Feedback:")
      /// AI is evaluating your sentence...
      public static let aiEvaluating = Loc.tr("Quizzes", "ai_quiz.ai_evaluating", fallback: "AI is evaluating your sentence...")
      /// Processing your answer...
      public static let aiProcessing = Loc.tr("Quizzes", "ai_quiz.ai_processing", fallback: "Processing your answer...")
      /// Type the word here...
      public static let blankPlaceholder = Loc.tr("Quizzes", "ai_quiz.blank_placeholder", fallback: "Type the word here...")
      /// Choose the sentence where '%@' is used correctly:
      public static func chooseCorrectSentence(_ p1: Any) -> String {
        return Loc.tr("Quizzes", "ai_quiz.choose_correct_sentence", String(describing: p1), fallback: "Choose the sentence where '%@' is used correctly:")
      }
      /// Hint: Consider the story context and word meaning
      public static let contextHint = Loc.tr("Quizzes", "ai_quiz.context_hint", fallback: "Hint: Consider the story context and word meaning")
      /// The word doesn't quite fit this context. Consider the story meaning.
      public static let contextMismatch = Loc.tr("Quizzes", "ai_quiz.context_mismatch", fallback: "The word doesn't quite fit this context. Consider the story meaning.")
      /// This sentence uses '%@' correctly because %@
      public static func correctUsageExplanation(_ p1: Any, _ p2: Any) -> String {
        return Loc.tr("Quizzes", "ai_quiz.correct_usage_explanation", String(describing: p1), String(describing: p2), fallback: "This sentence uses '%@' correctly because %@")
      }
      /// Detailed Explanations
      public static let detailedExplanations = Loc.tr("Quizzes", "ai_quiz.detailed_explanations", fallback: "Detailed Explanations")
      /// Evaluating with AI...
      public static let evaluatingWithAi = Loc.tr("Quizzes", "ai_quiz.evaluating_with_ai", fallback: "Evaluating with AI...")
      /// Excellent usage! Your sentence demonstrates perfect understanding.
      public static let excellentUsage = Loc.tr("Quizzes", "ai_quiz.excellent_usage", fallback: "Excellent usage! Your sentence demonstrates perfect understanding.")
      /// Explanation:
      public static let explanation = Loc.tr("Quizzes", "ai_quiz.explanation", fallback: "Explanation:")
      /// Fair usage. Consider the context and meaning more carefully.
      public static let fairUsage = Loc.tr("Quizzes", "ai_quiz.fair_usage", fallback: "Fair usage. Consider the context and meaning more carefully.")
      /// Feedback:
      public static let feedback = Loc.tr("Quizzes", "ai_quiz.feedback", fallback: "Feedback:")
      /// Fill in the blank with '%@':
      public static func fillInBlankStory(_ p1: Any) -> String {
        return Loc.tr("Quizzes", "ai_quiz.fill_in_blank_story", String(describing: p1), fallback: "Fill in the blank with '%@':")
      }
      /// Good! The word works well in this context.
      public static let goodContextFit = Loc.tr("Quizzes", "ai_quiz.good_context_fit", fallback: "Good! The word works well in this context.")
      /// Good usage! Your sentence shows good understanding with minor improvements possible.
      public static let goodUsage = Loc.tr("Quizzes", "ai_quiz.good_usage", fallback: "Good usage! Your sentence shows good understanding with minor improvements possible.")
      /// Grammar Score: %d/100
      public static func grammarScore(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "ai_quiz.grammar_score", p1, fallback: "Grammar Score: %d/100")
      }
      /// Incorrect usage. Review the word's meaning and try again.
      public static let incorrectUsage = Loc.tr("Quizzes", "ai_quiz.incorrect_usage", fallback: "Incorrect usage. Review the word's meaning and try again.")
      /// This sentence uses '%@' incorrectly because %@
      public static func incorrectUsageExplanation(_ p1: Any, _ p2: Any) -> String {
        return Loc.tr("Quizzes", "ai_quiz.incorrect_usage_explanation", String(describing: p1), String(describing: p2), fallback: "This sentence uses '%@' incorrectly because %@")
      }
      /// Option %d
      public static func option(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "ai_quiz.option", p1, fallback: "Option %d")
      }
      /// Overall Score: %d/100
      public static func overallScore(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "ai_quiz.overall_score", p1, fallback: "Overall Score: %d/100")
      }
      /// Perfect! The word fits perfectly in this context.
      public static let perfectContextFit = Loc.tr("Quizzes", "ai_quiz.perfect_context_fit", fallback: "Perfect! The word fits perfectly in this context.")
      /// Type your sentence here...
      public static let sentencePlaceholder = Loc.tr("Quizzes", "ai_quiz.sentence_placeholder", fallback: "Type your sentence here...")
      /// Skipped Word
      public static let skippedWord = Loc.tr("Quizzes", "ai_quiz.skipped_word", fallback: "Skipped Word")
      /// This word was skipped during the quiz. No evaluation is available for skipped words.
      public static let skippedWordMessage = Loc.tr("Quizzes", "ai_quiz.skipped_word_message", fallback: "This word was skipped during the quiz. No evaluation is available for skipped words.")
      /// Story Context:
      public static let storyContext = Loc.tr("Quizzes", "ai_quiz.story_context", fallback: "Story Context:")
      /// Submit for evaluation
      public static let submitForEvaluation = Loc.tr("Quizzes", "ai_quiz.submit_for_evaluation", fallback: "Submit for evaluation")
      /// Suggestions
      public static let suggestions = Loc.tr("Quizzes", "ai_quiz.suggestions", fallback: "Suggestions")
      /// Usage Score: %d/100
      public static func usageScore(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "ai_quiz.usage_score", p1, fallback: "Usage Score: %d/100")
      }
      /// View detailed explanations
      public static let viewDetailedExplanations = Loc.tr("Quizzes", "ai_quiz.view_detailed_explanations", fallback: "View detailed explanations")
      /// Write a sentence using '%@' correctly:
      public static func writeSentenceForWord(_ p1: Any) -> String {
        return Loc.tr("Quizzes", "ai_quiz.write_sentence_for_word", String(describing: p1), fallback: "Write a sentence using '%@' correctly:")
      }
      /// Your Sentence
      public static let yourSentence = Loc.tr("Quizzes", "ai_quiz.your_sentence", fallback: "Your Sentence")
    }
    public enum Loading {
      /// AI is creating multiple choice questions to test your understanding of word usage in context.
      public static let contextQuestionsDescription = Loc.tr("Quizzes", "loading.context_questions_description", fallback: "AI is creating multiple choice questions to test your understanding of word usage in context.")
      /// Failed to load quiz
      public static let failedToLoadQuiz = Loc.tr("Quizzes", "loading.failed_to_load_quiz", fallback: "Failed to load quiz")
      /// AI is creating engaging stories with blanks to test your understanding of word usage in context.
      public static let fillInBlankDescription = Loc.tr("Quizzes", "loading.fill_in_blank_description", fallback: "AI is creating engaging stories with blanks to test your understanding of word usage in context.")
      /// Generating context questions...
      public static let generatingContextQuestions = Loc.tr("Quizzes", "loading.generating_context_questions", fallback: "Generating context questions...")
      /// Generating fill-in-the-blank stories...
      public static let generatingFillInBlankStories = Loc.tr("Quizzes", "loading.generating_fill_in_blank_stories", fallback: "Generating fill-in-the-blank stories...")
      /// Loading next question...
      public static let loadingNextQuestion = Loc.tr("Quizzes", "loading.loading_next_question", fallback: "Loading next question...")
      /// Loading next story...
      public static let loadingNextStory = Loc.tr("Quizzes", "loading.loading_next_story", fallback: "Loading next story...")
      /// AI is preparing the next question for you.
      public static let preparingNextQuestion = Loc.tr("Quizzes", "loading.preparing_next_question", fallback: "AI is preparing the next question for you.")
      /// AI is preparing the next story for you.
      public static let preparingNextStory = Loc.tr("Quizzes", "loading.preparing_next_story", fallback: "AI is preparing the next story for you.")
    }
    public enum QuizActions {
      /// Finish
      public static let finish = Loc.tr("Quizzes", "quiz_actions.finish", fallback: "Finish")
      /// Incorrect. Try again
      public static let incorrectTryAgain = Loc.tr("Quizzes", "quiz_actions.incorrect_try_again", fallback: "Incorrect. Try again")
      /// Next Word
      public static let nextWord = Loc.tr("Quizzes", "quiz_actions.next_word", fallback: "Next Word")
      /// No difficult words available for quiz
      public static let noDifficultWordsAvailable = Loc.tr("Quizzes", "quiz_actions.no_difficult_words_available", fallback: "No difficult words available for quiz")
      /// Number of words
      public static let numberOfWords = Loc.tr("Quizzes", "quiz_actions.number_of_words", fallback: "Number of words")
      /// Submit Answer
      public static let submitAnswer = Loc.tr("Quizzes", "quiz_actions.submit_answer", fallback: "Submit Answer")
      /// Try harder :)
      public static let tryHarder = Loc.tr("Quizzes", "quiz_actions.try_harder", fallback: "Try harder :)")
      /// Your word is '%@'. Try harder :)
      public static func yourWordIs(_ p1: Any) -> String {
        return Loc.tr("Quizzes", "quiz_actions.your_word_is", String(describing: p1), fallback: "Your word is '%@'. Try harder :)")
      }
    }
    public enum QuizList {
      /// Add More Words
      public static let addMoreWords = Loc.tr("Quizzes", "quiz_list.add_more_words", fallback: "Add More Words")
      /// Add Words to Shared Dictionary
      public static let addWordsToSharedDictionary = Loc.tr("Quizzes", "quiz_list.add_words_to_shared_dictionary", fallback: "Add Words to Shared Dictionary")
      /// Add Your First Word
      public static let addYourFirstWord = Loc.tr("Quizzes", "quiz_list.add_your_first_word", fallback: "Add Your First Word")
      /// Configure your quiz experience
      public static let configureQuizExperience = Loc.tr("Quizzes", "quiz_list.configure_quiz_experience", fallback: "Configure your quiz experience")
      /// Focus on words that need review
      public static let focusOnWordsNeedReview = Loc.tr("Quizzes", "quiz_list.focus_on_words_need_review", fallback: "Focus on words that need review")
      /// Not enough words to review yet
      public static let notEnoughWordsReviewYet = Loc.tr("Quizzes", "quiz_list.not_enough_words_review_yet", fallback: "Not enough words to review yet")
      /// Practice Settings
      public static let practiceSettings = Loc.tr("Quizzes", "quiz_list.practice_settings", fallback: "Practice Settings")
      /// Quiz Types
      public static let quizTypes = Loc.tr("Quizzes", "quiz_list.quiz_types", fallback: "Quiz Types")
      /// Quizzes help you test your knowledge and reinforce learning!
      public static let quizzesHelpTestKnowledge = Loc.tr("Quizzes", "quiz_list.quizzes_help_test_knowledge", fallback: "Quizzes help you test your knowledge and reinforce learning!")
      /// You're %d words away from unlocking quizzes!
      public static func wordsAwayFromUnlockingQuizzes(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "quiz_list.words_away_from_unlocking_quizzes", p1, fallback: "You're %d words away from unlocking quizzes!")
      }
    }
    public enum QuizResults {
      /// Accuracy
      public static let accuracy = Loc.tr("Quizzes", "quiz_results.accuracy", fallback: "Accuracy")
      /// All Results
      public static let allResults = Loc.tr("Quizzes", "quiz_results.all_results", fallback: "All Results")
      /// Correct
      public static let correct = Loc.tr("Quizzes", "quiz_results.correct", fallback: "Correct")
      /// Duration
      public static let duration = Loc.tr("Quizzes", "quiz_results.duration", fallback: "Duration")
      /// No Quiz Results Yet
      public static let noQuizResultsYet = Loc.tr("Quizzes", "quiz_results.no_quiz_results_yet", fallback: "No Quiz Results Yet")
      /// Quiz
      public static let quiz = Loc.tr("Quizzes", "quiz_results.quiz", fallback: "Quiz")
      /// Time Period
      public static let timePeriod = Loc.tr("Quizzes", "quiz_results.time_period", fallback: "Time Period")
    }
    public enum QuizTypes {
      /// Choose the sentence where the word is used correctly
      public static let chooseCorrectUsage = Loc.tr("Quizzes", "quiz_types.choose_correct_usage", fallback: "Choose the sentence where the word is used correctly")
      /// Choose Definition
      public static let chooseDefinition = Loc.tr("Quizzes", "quiz_types.choose_definition", fallback: "Choose Definition")
      /// Context Usage
      public static let contextMultipleChoice = Loc.tr("Quizzes", "quiz_types.context_multiple_choice", fallback: "Context Usage")
      /// Fill in the blanks with the correct word in context
      public static let fillBlanksInContext = Loc.tr("Quizzes", "quiz_types.fill_blanks_in_context", fallback: "Fill in the blanks with the correct word in context")
      /// Fill in the Blank
      public static let fillInTheBlank = Loc.tr("Quizzes", "quiz_types.fill_in_the_blank", fallback: "Fill in the Blank")
      /// Great job! You've completed the context usage quiz.
      public static let greatJobCompletedContextQuiz = Loc.tr("Quizzes", "quiz_types.great_job_completed_context_quiz", fallback: "Great job! You've completed the context usage quiz.")
      /// Great job! You've completed the definition quiz.
      public static let greatJobCompletedDefinitionQuiz = Loc.tr("Quizzes", "quiz_types.great_job_completed_definition_quiz", fallback: "Great job! You've completed the definition quiz.")
      /// Great job! You've completed the fill in the blank quiz.
      public static let greatJobCompletedFillInTheBlankQuiz = Loc.tr("Quizzes", "quiz_types.great_job_completed_fill_in_the_blank_quiz", fallback: "Great job! You've completed the fill in the blank quiz.")
      /// Great job! You've completed the sentence writing quiz.
      public static let greatJobCompletedSentenceWritingQuiz = Loc.tr("Quizzes", "quiz_types.great_job_completed_sentence_writing_quiz", fallback: "Great job! You've completed the sentence writing quiz.")
      /// Great job! You've completed the spelling quiz.
      public static let greatJobCompletedSpellingQuiz = Loc.tr("Quizzes", "quiz_types.great_job_completed_spelling_quiz", fallback: "Great job! You've completed the spelling quiz.")
      /// Select the correct definition for each word
      public static let selectCorrectDefinition = Loc.tr("Quizzes", "quiz_types.select_correct_definition", fallback: "Select the correct definition for each word")
      /// Sentence Writing
      public static let sentenceWriting = Loc.tr("Quizzes", "quiz_types.sentence_writing", fallback: "Sentence Writing")
      /// Spelling Quiz
      public static let spellingQuiz = Loc.tr("Quizzes", "quiz_types.spelling_quiz", fallback: "Spelling Quiz")
      /// Test your spelling skills by typing words correctly
      public static let testSpellingSkills = Loc.tr("Quizzes", "quiz_types.test_spelling_skills", fallback: "Test your spelling skills by typing words correctly")
      /// Write sentences using words correctly with AI evaluation
      public static let writeSentencesWithAi = Loc.tr("Quizzes", "quiz_types.write_sentences_with_ai", fallback: "Write sentences using words correctly with AI evaluation")
    }
    public enum Ui {
      /// Options
      public static let options = Loc.tr("Quizzes", "ui.options", fallback: "Options")
      /// Question
      public static let question = Loc.tr("Quizzes", "ui.question", fallback: "Question")
      /// Question %d
      public static func questionNumber(_ p1: Int) -> String {
        return Loc.tr("Quizzes", "ui.question_number", p1, fallback: "Question %d")
      }
      /// Suggestions
      public static let suggestions = Loc.tr("Quizzes", "ui.suggestions", fallback: "Suggestions")
      /// You skipped this question. Here's the correct answer and explanation:
      public static let youSkippedQuestion = Loc.tr("Quizzes", "ui.you_skipped_question", fallback: "You skipped this question. Here's the correct answer and explanation:")
    }
  }
  public enum Settings {
    /// About App
    public static let aboutApp = Loc.tr("Settings", "about_app", fallback: "About App")
    /// I created this app because I could not find something that I wanted.
    /// 
    /// It is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.
    /// 
    /// I find this best to learn English. Hope it will work for you as well.
    /// 
    /// If you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!
    public static let aboutAppDescription = Loc.tr("Settings", "about_app_description", fallback: "I created this app because I could not find something that I wanted.\n\nIt is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.\n\nI find this best to learn English. Hope it will work for you as well.\n\nIf you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!")
    /// About My Dictionary
    public static let aboutMyDictionary = Loc.tr("Settings", "about_my_dictionary", fallback: "About My Dictionary")
    /// Accent
    public static let accent = Loc.tr("Settings", "accent", fallback: "Accent")
    /// Add and organize words with definitions
    public static let addOrganizeWords = Loc.tr("Settings", "add_organize_words", fallback: "Add and organize words with definitions")
    /// Anonymous
    public static let anonymous = Loc.tr("Settings", "anonymous", fallback: "Anonymous")
    /// App version:
    public static let appVersion = Loc.tr("Settings", "app_version", fallback: "App version:")
    /// Buy Me a Coffee
    public static let buyMeACoffee = Loc.tr("Settings", "buy_me_a_coffee", fallback: "Buy Me a Coffee")
    /// Check for Duplicates
    public static let checkForDuplicates = Loc.tr("Settings", "check_for_duplicates", fallback: "Check for Duplicates")
    /// Clean Up Duplicates
    public static let cleanUpDuplicates = Loc.tr("Settings", "clean_up_duplicates", fallback: "Clean Up Duplicates")
    /// Cleanup Completed
    public static let cleanupCompleted = Loc.tr("Settings", "cleanup_completed", fallback: "Cleanup Completed")
    /// Successfully cleaned up %d duplicates:
    /// • %d duplicate words
    /// • %d duplicate meanings
    /// • %d duplicate tags
    /// • %d meanings merged
    /// • %d tag relationships merged
    public static func cleanupCompletedMessage(_ p1: Int, _ p2: Int, _ p3: Int, _ p4: Int, _ p5: Int, _ p6: Int) -> String {
      return Loc.tr("Settings", "cleanup_completed_message", p1, p2, p3, p4, p5, p6, fallback: "Successfully cleaned up %d duplicates:\n• %d duplicate words\n• %d duplicate meanings\n• %d duplicate tags\n• %d meanings merged\n• %d tag relationships merged")
    }
    /// Contact Me
    public static let contactMe = Loc.tr("Settings", "contact_me", fallback: "Contact Me")
    /// Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!
    public static let contactSupport = Loc.tr("Settings", "contact_support", fallback: "Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!")
    /// Customize your learning experience
    public static let customizeLearningExperience = Loc.tr("Settings", "customize_learning_experience", fallback: "Customize your learning experience")
    /// Daily Reminders
    public static let dailyReminders = Loc.tr("Settings", "daily_reminders", fallback: "Daily Reminders")
    /// Get reminded at 8 PM if you haven't opened the app
    public static let dailyRemindersDescription = Loc.tr("Settings", "daily_reminders_description", fallback: "Get reminded at 8 PM if you haven't opened the app")
    /// Data Maintenance
    public static let dataMaintenance = Loc.tr("Settings", "data_maintenance", fallback: "Data Maintenance")
    /// Clean up duplicate words and meanings to improve app performance
    public static let dataMaintenanceDescription = Loc.tr("Settings", "data_maintenance_description", fallback: "Clean up duplicate words and meanings to improve app performance")
    /// Difficult Words
    public static let difficultWords = Loc.tr("Settings", "difficult_words", fallback: "Difficult Words")
    /// Get reminded at 4 PM to practice difficult words
    public static let difficultWordsDescription = Loc.tr("Settings", "difficult_words_description", fallback: "Get reminded at 4 PM to practice difficult words")
    /// Download backup from Google
    public static let downloadBackupFromGoogle = Loc.tr("Settings", "download_backup_from_google", fallback: "Download backup from Google")
    /// Download backup from Google
    public static let downloadBackupGoogle = Loc.tr("Settings", "download_backup_google", fallback: "Download backup from Google")
    /// Download Successful
    public static let downloadSuccessful = Loc.tr("Settings", "download_successful", fallback: "Download Successful")
    /// Duplicates Found
    public static let duplicatesFound = Loc.tr("Settings", "duplicates_found", fallback: "Duplicates Found")
    /// Found %d duplicate words, %d duplicate meanings, and %d duplicate tags. Use 'Clean Up Duplicates' to remove them.
    public static func duplicatesFoundMessage(_ p1: Int, _ p2: Int, _ p3: Int) -> String {
      return Loc.tr("Settings", "duplicates_found_message", p1, p2, p3, fallback: "Found %d duplicate words, %d duplicate meanings, and %d duplicate tags. Use 'Clean Up Duplicates' to remove them.")
    }
    /// Export Successful
    public static let exportSuccessful = Loc.tr("Settings", "export_successful", fallback: "Export Successful")
    /// Export words
    public static let exportWords = Loc.tr("Settings", "export_words", fallback: "Export words")
    /// Export Words
    public static let exportWordsTitle = Loc.tr("Settings", "export_words_title", fallback: "Export Words")
    /// Features
    public static let features = Loc.tr("Settings", "features", fallback: "Features")
    /// Free Plan
    public static let freePlan = Loc.tr("Settings", "free_plan", fallback: "Free Plan")
    /// Free users can export up to %d words
    public static func freeUsersExportLimit(_ p1: Int) -> String {
      return Loc.tr("Settings", "free_users_export_limit", p1, fallback: "Free users can export up to %d words")
    }
    /// Import / Export
    public static let importExport = Loc.tr("Settings", "import_export", fallback: "Import / Export")
    /// Please note that import and export only work with files created by this app.
    public static let importExportNote = Loc.tr("Settings", "import_export_note", fallback: "Please note that import and export only work with files created by this app.")
    /// Import and export your word collection
    public static let importExportWordCollection = Loc.tr("Settings", "import_export_word_collection", fallback: "Import and export your word collection")
    /// Import successful
    public static let importSuccessful = Loc.tr("Settings", "import_successful", fallback: "Import successful")
    /// %@ have been imported successfully
    public static func importSuccessfulMessage(_ p1: Any) -> String {
      return Loc.tr("Settings", "import_successful_message", String(describing: p1), fallback: "%@ have been imported successfully")
    }
    /// Import words
    public static let importWords = Loc.tr("Settings", "import_words", fallback: "Import words")
    /// Instagram
    public static let instagram = Loc.tr("Settings", "instagram", fallback: "Instagram")
    /// Learn more
    public static let learnMore = Loc.tr("Settings", "learn_more", fallback: "Learn more")
    /// Limited features available
    public static let limitedFeaturesAvailable = Loc.tr("Settings", "limited_features_available", fallback: "Limited features available")
    /// Manage Tags
    public static let manageTags = Loc.tr("Settings", "manage_tags", fallback: "Manage Tags")
    /// Manual sync mode: Use buttons below to upload/download your word lists to Google. Available to all users.
    public static let manualSyncModeDescription = Loc.tr("Settings", "manual_sync_mode_description", fallback: "Manual sync mode: Use buttons below to upload/download your word lists to Google. Available to all users.")
    /// No Duplicates
    public static let noDuplicates = Loc.tr("Settings", "no_duplicates", fallback: "No Duplicates")
    /// No duplicate words, meanings, or tags were found in your dictionary.
    public static let noDuplicatesMessage = Loc.tr("Settings", "no_duplicates_message", fallback: "No duplicate words, meanings, or tags were found in your dictionary.")
    /// No words imported
    public static let noWordsImported = Loc.tr("Settings", "no_words_imported", fallback: "No words imported")
    /// We couldn't find any new words to import
    public static let noWordsImportedMessage = Loc.tr("Settings", "no_words_imported_message", fallback: "We couldn't find any new words to import")
    /// Notifications
    public static let notifications = Loc.tr("Settings", "notifications", fallback: "Notifications")
    /// Organization
    public static let organization = Loc.tr("Settings", "organization", fallback: "Organization")
    /// Practice with quizzes and spelling exercises
    public static let practiceQuizzesSpelling = Loc.tr("Settings", "practice_quizzes_spelling", fallback: "Practice with quizzes and spelling exercises")
    /// Upgrade to Pro for unlimited features and cross-device sync.
    public static let proUpgradeDescription = Loc.tr("Settings", "pro_upgrade_description", fallback: "Upgrade to Pro for unlimited features and cross-device sync.")
    /// Pro User
    public static let proUser = Loc.tr("Settings", "pro_user", fallback: "Pro User")
    /// Rate the App
    public static let rateApp = Loc.tr("Settings", "rate_app", fallback: "Rate the App")
    /// Select accent
    public static let selectAccent = Loc.tr("Settings", "select_accent", fallback: "Select accent")
    /// Shared Dictionaries
    public static let sharedDictionaries = Loc.tr("Settings", "shared_dictionaries", fallback: "Shared Dictionaries")
    /// Show definitions in your native language
    public static let showDefinitionsNativeLanguage = Loc.tr("Settings", "show_definitions_native_language", fallback: "Show definitions in your native language")
    /// Sign in to sync word lists
    public static let signInSyncWordLists = Loc.tr("Settings", "sign_in_sync_word_lists", fallback: "Sign in to sync word lists")
    /// Sign in to create and share word lists with others.
    public static let signInToCreateShareWordLists = Loc.tr("Settings", "sign_in_to_create_share_word_lists", fallback: "Sign in to create and share word lists with others.")
    /// Sign in to sync word lists
    public static let signInToSyncWordLists = Loc.tr("Settings", "sign_in_to_sync_word_lists", fallback: "Sign in to sync word lists")
    /// Sign Out
    public static let signOut = Loc.tr("Settings", "sign_out", fallback: "Sign Out")
    /// Signed in as
    public static let signedInAs = Loc.tr("Settings", "signed_in_as", fallback: "Signed in as")
    /// Subscription
    public static let subscription = Loc.tr("Settings", "subscription", fallback: "Subscription")
    /// Support
    public static let support = Loc.tr("Settings", "support", fallback: "Support")
    /// Create and manage tags to organize your words, and add collaborators to share words with.
    public static let tagManagementDescription = Loc.tr("Settings", "tag_management_description", fallback: "Create and manage tags to organize your words, and add collaborators to share words with.")
    /// Track your learning progress
    public static let trackLearningProgress = Loc.tr("Settings", "track_learning_progress", fallback: "Track your learning progress")
    /// Translate Definitions
    public static let translateDefinitions = Loc.tr("Settings", "translate_definitions", fallback: "Translate Definitions")
    /// Upload backup to Google
    public static let uploadBackupGoogle = Loc.tr("Settings", "upload_backup_google", fallback: "Upload backup to Google")
    /// Upload backup to Google
    public static let uploadBackupToGoogle = Loc.tr("Settings", "upload_backup_to_google", fallback: "Upload backup to Google")
    /// Upload Successful
    public static let uploadSuccessful = Loc.tr("Settings", "upload_successful", fallback: "Upload Successful")
    /// Voice pronunciation support
    public static let voicePronunciationSupport = Loc.tr("Settings", "voice_pronunciation_support", fallback: "Voice pronunciation support")
    /// Word Lists & Sync
    public static let wordListsAndSync = Loc.tr("Settings", "word_lists_and_sync", fallback: "Word Lists & Sync")
    /// X (Twitter)
    public static let xTwitter = Loc.tr("Settings", "x_twitter", fallback: "X (Twitter)")
  }
  public enum SharedDictionaries {
    /// Add Collaborator
    public static let addCollaborator = Loc.tr("SharedDictionaries", "add_collaborator", fallback: "Add Collaborator")
    /// Add to Shared Dictionary
    public static let addToSharedDictionary = Loc.tr("SharedDictionaries", "add_to_shared_dictionary", fallback: "Add to Shared Dictionary")
    /// Add words to this shared dictionary to get started
    public static let addWordsToSharedDictionary = Loc.tr("SharedDictionaries", "add_words_to_shared_dictionary", fallback: "Add words to this shared dictionary to get started")
    /// Average Score
    public static let averageScore = Loc.tr("SharedDictionaries", "average_score", fallback: "Average Score")
    /// Be the first to rate this word's difficulty
    public static let beFirstToRateDifficulty = Loc.tr("SharedDictionaries", "be_first_to_rate_difficulty", fallback: "Be the first to rate this word's difficulty")
    /// • Can add, edit, and delete words
    public static let canAddEditDeleteWords = Loc.tr("SharedDictionaries", "can_add_edit_delete_words", fallback: "• Can add, edit, and delete words")
    /// • Can invite other collaborators
    public static let canInviteCollaborators = Loc.tr("SharedDictionaries", "can_invite_collaborators", fallback: "• Can invite other collaborators")
    /// • Can manage dictionary settings
    public static let canManageDictionarySettings = Loc.tr("SharedDictionaries", "can_manage_dictionary_settings", fallback: "• Can manage dictionary settings")
    /// • Can view all words
    public static let canViewAllWords = Loc.tr("SharedDictionaries", "can_view_all_words", fallback: "• Can view all words")
    /// • Cannot invite others
    public static let cannotInviteOthers = Loc.tr("SharedDictionaries", "cannot_invite_others", fallback: "• Cannot invite others")
    /// • Cannot make changes
    public static let cannotMakeChanges = Loc.tr("SharedDictionaries", "cannot_make_changes", fallback: "• Cannot make changes")
    /// Can't share word
    public static let cantShareWord = Loc.tr("SharedDictionaries", "cant_share_word", fallback: "Can't share word")
    /// Collaborate with others
    public static let collaborateOthers = Loc.tr("SharedDictionaries", "collaborate_others", fallback: "Collaborate with others")
    /// Collaborative Features
    public static let collaborativeFeatures = Loc.tr("SharedDictionaries", "collaborative_features", fallback: "Collaborative Features")
    /// The collaborator will be added with the email and name you provide. They will need to sign in with the same email address to access the shared dictionary.
    public static let collaboratorAddedEmailName = Loc.tr("SharedDictionaries", "collaborator_added_email_name", fallback: "The collaborator will be added with the email and name you provide. They will need to sign in with the same email address to access the shared dictionary.")
    /// The user will be added to the shared dictionary. They will receive a notification and can access the dictionary immediately.
    public static let collaboratorAddedWithEmailName = Loc.tr("SharedDictionaries", "collaborator_added_with_email_name", fallback: "The user will be added to the shared dictionary. They will receive a notification and can access the dictionary immediately.")
    /// Collaborator Details
    public static let collaboratorDetails = Loc.tr("SharedDictionaries", "collaborator_details", fallback: "Collaborator Details")
    /// Collaborators
    public static let collaborators = Loc.tr("SharedDictionaries", "collaborators", fallback: "Collaborators")
    /// %d collaborators
    public static func collaboratorsCount(_ p1: Int) -> String {
      return Loc.tr("SharedDictionaries", "collaborators_count", p1, fallback: "%d collaborators")
    }
    /// Create a shared dictionary to collaborate with others
    public static let createSharedDictionary = Loc.tr("SharedDictionaries", "create_shared_dictionary", fallback: "Create a shared dictionary to collaborate with others")
    /// Create a shared dictionary to collaborate with others
    public static let createSharedDictionaryCollaborate = Loc.tr("SharedDictionaries", "create_shared_dictionary_collaborate", fallback: "Create a shared dictionary to collaborate with others")
    /// Created
    public static let created = Loc.tr("SharedDictionaries", "created", fallback: "Created")
    /// Created by %@
    public static func createdBy(_ p1: Any) -> String {
      return Loc.tr("SharedDictionaries", "created_by", String(describing: p1), fallback: "Created by %@")
    }
    /// Delete Dictionary
    public static let deleteDictionary = Loc.tr("SharedDictionaries", "delete_dictionary", fallback: "Delete Dictionary")
    /// Dictionaries
    public static let dictionaries = Loc.tr("SharedDictionaries", "dictionaries", fallback: "Dictionaries")
    /// This dictionary may have been deleted or you may have lost access to it.
    public static let dictionaryDeletedOrLostAccess = Loc.tr("SharedDictionaries", "dictionary_deleted_or_lost_access", fallback: "This dictionary may have been deleted or you may have lost access to it.")
    /// Dictionary Details
    public static let dictionaryDetails = Loc.tr("SharedDictionaries", "dictionary_details", fallback: "Dictionary Details")
    /// Dictionary Info
    public static let dictionaryInfo = Loc.tr("SharedDictionaries", "dictionary_info", fallback: "Dictionary Info")
    /// Dictionary name is required
    public static let dictionaryNameRequired = Loc.tr("SharedDictionaries", "dictionary_name_required", fallback: "Dictionary name is required")
    /// Dictionary Selected
    public static let dictionarySelected = Loc.tr("SharedDictionaries", "dictionary_selected", fallback: "Dictionary Selected")
    /// Editor
    public static let editor = Loc.tr("SharedDictionaries", "editor", fallback: "Editor")
    /// Editor:
    public static let editorDescription = Loc.tr("SharedDictionaries", "editor_description", fallback: "Editor:")
    /// Editor:
    public static let editorRole = Loc.tr("SharedDictionaries", "editor_role", fallback: "Editor:")
    /// Enter dictionary name
    public static let enterDictionaryName = Loc.tr("SharedDictionaries", "enter_dictionary_name", fallback: "Enter dictionary name")
    /// Free users can create one shared dictionary
    public static let freeUsersOneDictionary = Loc.tr("SharedDictionaries", "free_users_one_dictionary", fallback: "Free users can create one shared dictionary")
    /// Me
    public static let me = Loc.tr("SharedDictionaries", "me", fallback: "Me")
    /// Name
    public static let name = Loc.tr("SharedDictionaries", "name", fallback: "Name")
    /// New Shared Dictionary
    public static let newSharedDictionary = Loc.tr("SharedDictionaries", "new_shared_dictionary", fallback: "New Shared Dictionary")
    /// No Results
    public static let noResults = Loc.tr("SharedDictionaries", "no_results", fallback: "No Results")
    /// No Shared Dictionaries
    public static let noSharedDictionaries = Loc.tr("SharedDictionaries", "no_shared_dictionaries", fallback: "No Shared Dictionaries")
    /// No shared dictionaries
    public static let noSharedDictionariesSidebar = Loc.tr("SharedDictionaries", "no_shared_dictionaries_sidebar", fallback: "No shared dictionaries")
    /// No words match your current filter
    public static let noWordsMatchFilter = Loc.tr("SharedDictionaries", "no_words_match_filter", fallback: "No words match your current filter")
    /// No words yet
    public static let noWordsYet = Loc.tr("SharedDictionaries", "no_words_yet", fallback: "No words yet")
    /// Note
    public static let note = Loc.tr("SharedDictionaries", "note", fallback: "Note")
    /// of 1 dictionary created
    public static let ofDictionaryCreated = Loc.tr("SharedDictionaries", "of_dictionary_created", fallback: "of 1 dictionary created")
    /// Owner
    public static let owner = Loc.tr("SharedDictionaries", "owner", fallback: "Owner")
    /// Private
    public static let privateDictionary = Loc.tr("SharedDictionaries", "private_dictionary", fallback: "Private")
    /// Role Permissions
    public static let rolePermissions = Loc.tr("SharedDictionaries", "role_permissions", fallback: "Role Permissions")
    /// Save to your personal dictionary
    public static let saveToPersonalDictionary = Loc.tr("SharedDictionaries", "save_to_personal_dictionary", fallback: "Save to your personal dictionary")
    /// Score: %d
    public static func score(_ p1: Int) -> String {
      return Loc.tr("SharedDictionaries", "score", p1, fallback: "Score: %d")
    }
    /// Select role
    public static let selectRole = Loc.tr("SharedDictionaries", "select_role", fallback: "Select role")
    /// Shared Dictionaries
    public static let sharedDictionaries = Loc.tr("SharedDictionaries", "shared_dictionaries", fallback: "Shared Dictionaries")
    /// Please sign in to create a shared dictionary
    public static let signInToCreateSharedDictionary = Loc.tr("SharedDictionaries", "sign_in_to_create_shared_dictionary", fallback: "Please sign in to create a shared dictionary")
    /// Viewer
    public static let viewer = Loc.tr("SharedDictionaries", "viewer", fallback: "Viewer")
    /// Viewer:
    public static let viewerDescription = Loc.tr("SharedDictionaries", "viewer_description", fallback: "Viewer:")
    /// Viewer:
    public static let viewerRole = Loc.tr("SharedDictionaries", "viewer_role", fallback: "Viewer:")
    /// Your Dictionaries
    public static let yourDictionaries = Loc.tr("SharedDictionaries", "your_dictionaries", fallback: "Your Dictionaries")
    /// Your Role
    public static let yourRole = Loc.tr("SharedDictionaries", "your_role", fallback: "Your Role")
    /// Your score
    public static let yourScore = Loc.tr("SharedDictionaries", "your_score", fallback: "Your score")
    /// Your status
    public static let yourStatus = Loc.tr("SharedDictionaries", "your_status", fallback: "Your status")
    public enum CollaboratorManagement {
      /// Add
      public static let add = Loc.tr("SharedDictionaries", "collaborator_management.add", fallback: "Add")
      /// Add Collaborator
      public static let addCollaborator = Loc.tr("SharedDictionaries", "collaborator_management.add_collaborator", fallback: "Add Collaborator")
      /// Continue
      public static let `continue` = Loc.tr("SharedDictionaries", "collaborator_management.continue", fallback: "Continue")
      /// Delete Dictionary
      public static let deleteDictionary = Loc.tr("SharedDictionaries", "collaborator_management.delete_dictionary", fallback: "Delete Dictionary")
      /// Are you sure you want to delete this shared dictionary? This action cannot be undone.
      public static let deleteDictionaryConfirmation = Loc.tr("SharedDictionaries", "collaborator_management.delete_dictionary_confirmation", fallback: "Are you sure you want to delete this shared dictionary? This action cannot be undone.")
      /// Dictionary Details
      public static let dictionaryDetails = Loc.tr("SharedDictionaries", "collaborator_management.dictionary_details", fallback: "Dictionary Details")
      /// Dictionary Not Found
      public static let dictionaryNotFound = Loc.tr("SharedDictionaries", "collaborator_management.dictionary_not_found", fallback: "Dictionary Not Found")
      /// Email address is required
      public static let emailAddressRequired = Loc.tr("SharedDictionaries", "collaborator_management.email_address_required", fallback: "Email address is required")
      /// Make Editor
      public static let makeEditor = Loc.tr("SharedDictionaries", "collaborator_management.make_editor", fallback: "Make Editor")
      /// Make Viewer
      public static let makeViewer = Loc.tr("SharedDictionaries", "collaborator_management.make_viewer", fallback: "Make Viewer")
      /// Remove
      public static let remove = Loc.tr("SharedDictionaries", "collaborator_management.remove", fallback: "Remove")
      /// Role
      public static let role = Loc.tr("SharedDictionaries", "collaborator_management.role", fallback: "Role")
      /// Stop watching
      public static let stopWatching = Loc.tr("SharedDictionaries", "collaborator_management.stop_watching", fallback: "Stop watching")
      /// Stop watching dictionary
      public static let stopWatchingDictionary = Loc.tr("SharedDictionaries", "collaborator_management.stop_watching_dictionary", fallback: "Stop watching dictionary")
      /// Are you sure you want to stop watching this shared dictionary?
      public static let stopWatchingDictionaryConfirmation = Loc.tr("SharedDictionaries", "collaborator_management.stop_watching_dictionary_confirmation", fallback: "Are you sure you want to stop watching this shared dictionary?")
      /// Unknown
      public static let unknown = Loc.tr("SharedDictionaries", "collaborator_management.unknown", fallback: "Unknown")
      /// Please enter a valid email address
      public static let validEmailAddress = Loc.tr("SharedDictionaries", "collaborator_management.valid_email_address", fallback: "Please enter a valid email address")
    }
    public enum CollaboratorRoles {
      /// Editor
      public static let editor = Loc.tr("SharedDictionaries", "collaborator_roles.editor", fallback: "Editor")
      /// Owner
      public static let owner = Loc.tr("SharedDictionaries", "collaborator_roles.owner", fallback: "Owner")
      /// Viewer
      public static let viewer = Loc.tr("SharedDictionaries", "collaborator_roles.viewer", fallback: "Viewer")
    }
    public enum SharedDictionarySelection {
      /// Add to Shared
      public static let addToShared = Loc.tr("SharedDictionaries", "shared_dictionary_selection.add_to_shared", fallback: "Add to Shared")
      /// Add Word to Shared Dictionary
      public static let addWordToSharedDictionary = Loc.tr("SharedDictionaries", "shared_dictionary_selection.add_word_to_shared_dictionary", fallback: "Add Word to Shared Dictionary")
      /// Dictionary Selected
      public static let dictionarySelected = Loc.tr("SharedDictionaries", "shared_dictionary_selection.dictionary_selected", fallback: "Dictionary Selected")
      /// Select Dictionary
      public static let selectDictionary = Loc.tr("SharedDictionaries", "shared_dictionary_selection.select_dictionary", fallback: "Select Dictionary")
      /// unknown
      public static let unknown = Loc.tr("SharedDictionaries", "shared_dictionary_selection.unknown", fallback: "unknown")
    }
  }
  public enum Subscription {
    public enum Paywall {
      /// Active Users
      public static let activeUsers = Loc.tr("Subscription", "paywall.active_users", fallback: "Active Users")
      /// App Store Rating
      public static let appStoreRating = Loc.tr("Subscription", "paywall.app_store_rating", fallback: "App Store Rating")
      /// By subscribing, you agree to our Terms of Service and Privacy Policy
      public static let bySubscribingAgreeTerms = Loc.tr("Subscription", "paywall.by_subscribing_agree_terms", fallback: "By subscribing, you agree to our Terms of Service and Privacy Policy")
      /// Choose Your Plan
      public static let chooseYourPlan = Loc.tr("Subscription", "paywall.choose_your_plan", fallback: "Choose Your Plan")
      /// Collaborate
      public static let collaborate = Loc.tr("Subscription", "paywall.collaborate", fallback: "Collaborate")
      /// Everything you need to master vocabulary
      public static let everythingYouNeedToMasterVocabulary = Loc.tr("Subscription", "paywall.everything_you_need_to_master_vocabulary", fallback: "Everything you need to master vocabulary")
      /// Failed to restore purchases: %@
      public static func failedToRestorePurchases(_ p1: Any) -> String {
        return Loc.tr("Subscription", "paywall.failed_to_restore_purchases", String(describing: p1), fallback: "Failed to restore purchases: %@")
      }
      /// Free Plan
      public static let freePlan = Loc.tr("Subscription", "paywall.free_plan", fallback: "Free Plan")
      /// Join thousands of users who've transformed their vocabulary learning
      public static let joinThousandsUsers = Loc.tr("Subscription", "paywall.join_thousands_users", fallback: "Join thousands of users who've transformed their vocabulary learning")
      /// Learn with others
      public static let learnWithOthers = Loc.tr("Subscription", "paywall.learn_with_others", fallback: "Learn with others")
      /// Limited features available
      public static let limitedFeaturesAvailable = Loc.tr("Subscription", "paywall.limited_features_available", fallback: "Limited features available")
      /// No active subscriptions found. Please check your App Store account.
      public static let noActiveSubscriptionsFound = Loc.tr("Subscription", "paywall.no_active_subscriptions_found", fallback: "No active subscriptions found. Please check your App Store account.")
      /// Privacy Policy
      public static let privacyPolicy = Loc.tr("Subscription", "paywall.privacy_policy", fallback: "Privacy Policy")
      /// Pro User
      public static let proUser = Loc.tr("Subscription", "paywall.pro_user", fallback: "Pro User")
      /// Restore Purchases
      public static let restorePurchases = Loc.tr("Subscription", "paywall.restore_purchases", fallback: "Restore Purchases")
      /// Save %@
      public static func savePercentage(_ p1: Any) -> String {
        return Loc.tr("Subscription", "paywall.save_percentage", String(describing: p1), fallback: "Save %@")
      }
      /// See your improvement
      public static let seeYourImprovement = Loc.tr("Subscription", "paywall.see_your_improvement", fallback: "See your improvement")
      /// Sign In Required
      public static let signInRequired = Loc.tr("Subscription", "paywall.sign_in_required", fallback: "Sign In Required")
      /// Start Pro Subscription
      public static let startProSubscription = Loc.tr("Subscription", "paywall.start_pro_subscription", fallback: "Start Pro Subscription")
      /// Terms of Service
      public static let termsOfService = Loc.tr("Subscription", "paywall.terms_of_service", fallback: "Terms of Service")
      /// Track Progress
      public static let trackProgress = Loc.tr("Subscription", "paywall.track_progress", fallback: "Track Progress")
      /// Trusted by learners worldwide
      public static let trustedByLearnersWorldwide = Loc.tr("Subscription", "paywall.trusted_by_learners_worldwide", fallback: "Trusted by learners worldwide")
      /// Upgrade to Pro
      public static let upgradeToPro = Loc.tr("Subscription", "paywall.upgrade_to_pro", fallback: "Upgrade to Pro")
      /// Words Added
      public static let wordsAdded = Loc.tr("Subscription", "paywall.words_added", fallback: "Words Added")
    }
    public enum ProFeatures {
      /// Advanced Analytics
      public static let advancedAnalytics = Loc.tr("Subscription", "pro_features.advanced_analytics", fallback: "Advanced Analytics")
      /// AI Definitions
      public static let aiDefinitions = Loc.tr("Subscription", "pro_features.ai_definitions", fallback: "AI Definitions")
      /// Get intelligent, context-aware definitions powered by advanced AI technology
      public static let aiDefinitionsDescription = Loc.tr("Subscription", "pro_features.ai_definitions_description", fallback: "Get intelligent, context-aware definitions powered by advanced AI technology")
      /// AI Quizzes
      public static let aiQuizzes = Loc.tr("Subscription", "pro_features.ai_quizzes", fallback: "AI Quizzes")
      /// Practice your vocabulary with personalized AI quizzes that adapt to your learning style.
      public static let aiQuizzesDescription = Loc.tr("Subscription", "pro_features.ai_quizzes_description", fallback: "Practice your vocabulary with personalized AI quizzes that adapt to your learning style.")
      /// Create and manage shared dictionaries with others
      public static let createManageSharedDictionaries = Loc.tr("Subscription", "pro_features.create_manage_shared_dictionaries", fallback: "Create and manage shared dictionaries with others")
      /// Create Shared Dictionaries
      public static let createSharedDictionaries = Loc.tr("Subscription", "pro_features.create_shared_dictionaries", fallback: "Create Shared Dictionaries")
      /// Get detailed insights into your learning progress
      public static let detailedInsights = Loc.tr("Subscription", "pro_features.detailed_insights", fallback: "Get detailed insights into your learning progress")
      /// Detailed progress tracking and insights
      public static let detailedProgressTracking = Loc.tr("Subscription", "pro_features.detailed_progress_tracking", fallback: "Detailed progress tracking and insights")
      /// Export unlimited words to CSV files
      public static let exportUnlimitedWords = Loc.tr("Subscription", "pro_features.export_unlimited_words", fallback: "Export unlimited words to CSV files")
      /// Get priority support when you need help
      public static let getPrioritySupport = Loc.tr("Subscription", "pro_features.get_priority_support", fallback: "Get priority support when you need help")
      /// Google Sync
      public static let googleSync = Loc.tr("Subscription", "pro_features.google_sync", fallback: "Google Sync")
      /// Organize your words with custom tags for easier search
      public static let organizeWordsWithTags = Loc.tr("Subscription", "pro_features.organize_words_with_tags", fallback: "Organize your words with custom tags for easier search")
      /// Priority Support
      public static let prioritySupport = Loc.tr("Subscription", "pro_features.priority_support", fallback: "Priority Support")
      /// Get priority support from our team
      public static let prioritySupportTeam = Loc.tr("Subscription", "pro_features.priority_support_team", fallback: "Get priority support from our team")
      /// Pro Features
      public static let proFeatures = Loc.tr("Subscription", "pro_features.pro_features", fallback: "Pro Features")
      /// Speechify TTS
      public static let speechifyTts = Loc.tr("Subscription", "pro_features.speechify_tts", fallback: "Speechify TTS")
      /// Access to Speechify's premium text-to-speech technology. Hundreds of natural-sounding premium voices
      public static let speechifyTtsDescription = Loc.tr("Subscription", "pro_features.speechify_tts_description", fallback: "Access to Speechify's premium text-to-speech technology. Hundreds of natural-sounding premium voices")
      /// Sync your words across all devices with Google Drive
      public static let syncWordsAcrossDevices = Loc.tr("Subscription", "pro_features.sync_words_across_devices", fallback: "Sync your words across all devices with Google Drive")
      /// Tag Management
      public static let tagManagement = Loc.tr("Subscription", "pro_features.tag_management", fallback: "Tag Management")
      /// Unlimited Export
      public static let unlimitedExport = Loc.tr("Subscription", "pro_features.unlimited_export", fallback: "Unlimited Export")
      /// Unlock all Pro features
      public static let unlockAllProFeatures = Loc.tr("Subscription", "pro_features.unlock_all_pro_features", fallback: "Unlock all Pro features")
    }
    public enum ProUpgrade {
      /// Time Period
      public static let timePeriod = Loc.tr("Subscription", "pro_upgrade.time_period", fallback: "Time Period")
      /// Upgrade to Pro to see full progress details.
      public static let upgradeToProProgressDetails = Loc.tr("Subscription", "pro_upgrade.upgrade_to_pro_progress_details", fallback: "Upgrade to Pro to see full progress details.")
      /// Upgrade to Pro to see full vocabulary growth details.
      public static let upgradeToProVocabularyGrowth = Loc.tr("Subscription", "pro_upgrade.upgrade_to_pro_vocabulary_growth", fallback: "Upgrade to Pro to see full vocabulary growth details.")
    }
  }
  public enum Tags {
    /// Add your first tag by tapping the button above.
    public static let addFirstTag = Loc.tr("Tags", "add_first_tag", fallback: "Add your first tag by tapping the button above.")
    /// Add your first tag by tapping the button above.
    public static let addFirstTagDescription = Loc.tr("Tags", "add_first_tag_description", fallback: "Add your first tag by tapping the button above.")
    /// Add Tag
    public static let addTag = Loc.tr("Tags", "add_tag", fallback: "Add Tag")
    /// Add a tag to start using it.
    public static let addTagToStartUsing = Loc.tr("Tags", "add_tag_to_start_using", fallback: "Add a tag to start using it.")
    /// Add Tags
    public static let addTags = Loc.tr("Tags", "add_tags", fallback: "Add Tags")
    /// Create tags
    public static let createTags = Loc.tr("Tags", "create_tags", fallback: "Create tags")
    /// Delete Tag
    public static let deleteTag = Loc.tr("Tags", "delete_tag", fallback: "Delete Tag")
    /// This action cannot be undone.
    public static let deleteTagCannotUndo = Loc.tr("Tags", "delete_tag_cannot_undo", fallback: "This action cannot be undone.")
    /// Are you sure you want to delete this tag?
    public static let deleteTagConfirmation = Loc.tr("Tags", "delete_tag_confirmation", fallback: "Are you sure you want to delete this tag?")
    /// Edit Tag
    public static let editTag = Loc.tr("Tags", "edit_tag", fallback: "Edit Tag")
    /// Manage Tags
    public static let manageTags = Loc.tr("Tags", "manage_tags", fallback: "Manage Tags")
    /// New Tag
    public static let newTag = Loc.tr("Tags", "new_tag", fallback: "New Tag")
    /// No Tags added yet
    public static let noTagsYet = Loc.tr("Tags", "no_tags_yet", fallback: "No Tags added yet")
    /// Tag Color
    public static let tagColor = Loc.tr("Tags", "tag_color", fallback: "Tag Color")
    /// Select a color to help identify your tag
    public static let tagColorHelp = Loc.tr("Tags", "tag_color_help", fallback: "Select a color to help identify your tag")
    /// Tag Management Error
    public static let tagManagementError = Loc.tr("Tags", "tag_management_error", fallback: "Tag Management Error")
    /// Tag Name
    public static let tagName = Loc.tr("Tags", "tag_name", fallback: "Tag Name")
    /// Choose a descriptive name for your tag
    public static let tagNameHelp = Loc.tr("Tags", "tag_name_help", fallback: "Choose a descriptive name for your tag")
    /// Tags help you organize your words. Each word can have up to 5 tags.
    public static let tagsHelpText = Loc.tr("Tags", "tags_help_text", fallback: "Tags help you organize your words. Each word can have up to 5 tags.")
    /// Type tag name...
    public static let typeTagName = Loc.tr("Tags", "type_tag_name", fallback: "Type tag name...")
    public enum TagColors {
      /// Blue
      public static let blue = Loc.tr("Tags", "tag_colors.blue", fallback: "Blue")
      /// Gray
      public static let gray = Loc.tr("Tags", "tag_colors.gray", fallback: "Gray")
      /// Green
      public static let green = Loc.tr("Tags", "tag_colors.green", fallback: "Green")
      /// Orange
      public static let orange = Loc.tr("Tags", "tag_colors.orange", fallback: "Orange")
      /// Pink
      public static let pink = Loc.tr("Tags", "tag_colors.pink", fallback: "Pink")
      /// Purple
      public static let purple = Loc.tr("Tags", "tag_colors.purple", fallback: "Purple")
      /// Red
      public static let red = Loc.tr("Tags", "tag_colors.red", fallback: "Red")
      /// Yellow
      public static let yellow = Loc.tr("Tags", "tag_colors.yellow", fallback: "Yellow")
    }
    public enum TagSelection {
      /// No Tags Yet
      public static let noTagsYet = Loc.tr("Tags", "tag_selection.no_tags_yet", fallback: "No Tags Yet")
      /// Select Tags
      public static let selectTags = Loc.tr("Tags", "tag_selection.select_tags", fallback: "Select Tags")
      /// You can select up to 5 tags per word. Tap a tag to select or deselect it.
      public static let youCanSelectUpTo5Tags = Loc.tr("Tags", "tag_selection.you_can_select_up_to_5_tags", fallback: "You can select up to 5 tags per word. Tap a tag to select or deselect it.")
    }
  }
  public enum Tts {
    /// Advertisement
    public static let advertisement = Loc.tr("TTS", "advertisement", fallback: "Advertisement")
    /// American Neutral
    public static let americanNeutral = Loc.tr("TTS", "american-neutral", fallback: "American Neutral")
    /// Angry
    public static let angry = Loc.tr("TTS", "angry", fallback: "Angry")
    /// Animation
    public static let animation = Loc.tr("TTS", "animation", fallback: "Animation")
    /// Assertive or Confident
    public static let assertiveOrConfident = Loc.tr("TTS", "assertive-or-confident", fallback: "Assertive or Confident")
    /// Audio Settings
    public static let audioSettings = Loc.tr("TTS", "audio_settings", fallback: "Audio Settings")
    /// Audiobook
    public static let audiobook = Loc.tr("TTS", "audiobook", fallback: "Audiobook")
    /// Audiobook & Narration
    public static let audiobookAndNarration = Loc.tr("TTS", "audiobook-and-narration", fallback: "Audiobook & Narration")
    /// Audiobooks & Narration
    public static let audiobooksAndNarration = Loc.tr("TTS", "audiobooks-and-narration", fallback: "Audiobooks & Narration")
    /// Australian
    public static let australian = Loc.tr("TTS", "australian", fallback: "Australian")
    /// Bright
    public static let bright = Loc.tr("TTS", "bright", fallback: "Bright")
    /// British
    public static let british = Loc.tr("TTS", "british", fallback: "British")
    /// Calm or Relaxed
    public static let calmOrRelaxed = Loc.tr("TTS", "calm-or-relaxed", fallback: "Calm or Relaxed")
    /// Change Voice
    public static let changeVoice = Loc.tr("TTS", "change_voice", fallback: "Change Voice")
    /// characters
    public static let characters = Loc.tr("TTS", "characters", fallback: "characters")
    /// Cheerful
    public static let cheerful = Loc.tr("TTS", "cheerful", fallback: "Cheerful")
    /// Conversational
    public static let conversational = Loc.tr("TTS", "conversational", fallback: "Conversational")
    /// Crisp
    public static let crisp = Loc.tr("TTS", "crisp", fallback: "Crisp")
    /// Current Voice
    public static let currentVoice = Loc.tr("TTS", "current_voice", fallback: "Current Voice")
    /// Customize your text-to-speech experience
    public static let customizeTtsExperience = Loc.tr("TTS", "customize_tts_experience", fallback: "Customize your text-to-speech experience")
    /// TTS Dashboard
    public static let dashboard = Loc.tr("TTS", "dashboard", fallback: "TTS Dashboard")
    /// Deep
    public static let deep = Loc.tr("TTS", "deep", fallback: "Deep")
    /// Default Voice
    public static let defaultVoice = Loc.tr("TTS", "default_voice", fallback: "Default Voice")
    /// Direct
    public static let direct = Loc.tr("TTS", "direct", fallback: "Direct")
    /// E-Learning
    public static let eLearning = Loc.tr("TTS", "e-learning", fallback: "E-Learning")
    /// Energetic
    public static let energetic = Loc.tr("TTS", "energetic", fallback: "Energetic")
    /// Enter text to test...
    public static let enterTextToTest = Loc.tr("TTS", "enter_text_to_test", fallback: "Enter text to test...")
    /// Fearful
    public static let fearful = Loc.tr("TTS", "fearful", fallback: "Fearful")
    /// Female
    public static let female = Loc.tr("TTS", "female", fallback: "Female")
    /// Free Google TTS with basic voices and reliable performance
    public static let freeGoogleTtsDescription = Loc.tr("TTS", "free_google_tts_description", fallback: "Free Google TTS with basic voices and reliable performance")
    /// Gaming
    public static let gaming = Loc.tr("TTS", "gaming", fallback: "Gaming")
    /// High Pitch
    public static let highPitch = Loc.tr("TTS", "high-pitch", fallback: "High Pitch")
    /// Indian
    public static let indian = Loc.tr("TTS", "indian", fallback: "Indian")
    /// Male
    public static let male = Loc.tr("TTS", "male", fallback: "Male")
    /// Meditation
    public static let meditation = Loc.tr("TTS", "meditation", fallback: "Meditation")
    /// Middle-aged
    public static let middleAged = Loc.tr("TTS", "middle-aged", fallback: "Middle-aged")
    /// Monthly Limit
    public static let monthlyLimit = Loc.tr("TTS", "monthly_limit", fallback: "Monthly Limit")
    /// Movie
    public static let movie = Loc.tr("TTS", "movie", fallback: "Movie")
    /// Movies, Acting & Gaming
    public static let moviesActingAndGaming = Loc.tr("TTS", "movies-acting-and-gaming", fallback: "Movies, Acting & Gaming")
    /// Narration
    public static let narration = Loc.tr("TTS", "narration", fallback: "Narration")
    /// Neutral
    public static let neutral = Loc.tr("TTS", "neutral", fallback: "Neutral")
    /// Nigerian
    public static let nigerian = Loc.tr("TTS", "nigerian", fallback: "Nigerian")
    /// Playing
    public static let playing = Loc.tr("TTS", "playing", fallback: "Playing")
    /// Podcast
    public static let podcast = Loc.tr("TTS", "podcast", fallback: "Podcast")
    /// Premium TTS Dashboard
    public static let premiumTtsDashboard = Loc.tr("TTS", "premium_tts_dashboard", fallback: "Premium TTS Dashboard")
    /// Preview Current Voice
    public static let previewCurrentVoice = Loc.tr("TTS", "preview_current_voice", fallback: "Preview Current Voice")
    /// PRO
    public static let pro = Loc.tr("TTS", "pro", fallback: "PRO")
    /// Professional
    public static let professional = Loc.tr("TTS", "professional", fallback: "Professional")
    /// Provider
    public static let provider = Loc.tr("TTS", "provider", fallback: "Provider")
    /// Ready
    public static let ready = Loc.tr("TTS", "ready", fallback: "Ready")
    /// Relaxed
    public static let relaxed = Loc.tr("TTS", "relaxed", fallback: "Relaxed")
    /// Remaining
    public static let remaining = Loc.tr("TTS", "remaining", fallback: "Remaining")
    /// Sad
    public static let sad = Loc.tr("TTS", "sad", fallback: "Sad")
    /// Senior
    public static let senior = Loc.tr("TTS", "senior", fallback: "Senior")
    /// Social Media
    public static let socialMedia = Loc.tr("TTS", "social-media", fallback: "Social Media")
    /// Speech Rate
    public static let speechRate = Loc.tr("TTS", "speech_rate", fallback: "Speech Rate")
    /// Speechify Monthly Usage
    public static let speechifyMonthlyUsage = Loc.tr("TTS", "speechify_monthly_usage", fallback: "Speechify Monthly Usage")
    /// Stop
    public static let stop = Loc.tr("TTS", "stop", fallback: "Stop")
    /// Surprised
    public static let suprised = Loc.tr("TTS", "suprised", fallback: "Surprised")
    /// Surprised
    public static let surprised = Loc.tr("TTS", "surprised", fallback: "Surprised")
    /// Teen
    public static let teen = Loc.tr("TTS", "teen", fallback: "Teen")
    /// Terrified
    public static let terrified = Loc.tr("TTS", "terrified", fallback: "Terrified")
    /// Test
    public static let test = Loc.tr("TTS", "test", fallback: "Test")
    /// Test Your Settings
    public static let testYourSettings = Loc.tr("TTS", "test_your_settings", fallback: "Test Your Settings")
    /// TTS Provider
    public static let ttsProvider = Loc.tr("TTS", "tts_provider", fallback: "TTS Provider")
    /// Usage Progress
    public static let usageProgress = Loc.tr("TTS", "usage_progress", fallback: "Usage Progress")
    /// Usage Statistics
    public static let usageStatistics = Loc.tr("TTS", "usage_statistics", fallback: "Usage Statistics")
    /// Used This Month
    public static let usedThisMonth = Loc.tr("TTS", "used_this_month", fallback: "Used This Month")
    /// Voice Customization
    public static let voiceCustomization = Loc.tr("TTS", "voice_customization", fallback: "Voice Customization")
    /// Volume
    public static let volume = Loc.tr("TTS", "volume", fallback: "Volume")
    /// Warm
    public static let warm = Loc.tr("TTS", "warm", fallback: "Warm")
    /// Warm or Friendly
    public static let warmOrFriendly = Loc.tr("TTS", "warm-or-friendly", fallback: "Warm or Friendly")
    /// Young Adult
    public static let youngAdult = Loc.tr("TTS", "young-adult", fallback: "Young Adult")
    public enum Analytics {
      /// Characters Used
      public static let charactersUsed = Loc.tr("TTS", "analytics.characters_used", fallback: "Characters Used")
      /// Favorite Language
      public static let favoriteLanguage = Loc.tr("TTS", "analytics.favorite_language", fallback: "Favorite Language")
      /// Favorite Voice
      public static let favoriteVoice = Loc.tr("TTS", "analytics.favorite_voice", fallback: "Favorite Voice")
      /// Premium Usage
      public static let premiumUsage = Loc.tr("TTS", "analytics.premium_usage", fallback: "Premium Usage")
      /// Sessions
      public static let sessions = Loc.tr("TTS", "analytics.sessions", fallback: "Sessions")
      /// Time Saved
      public static let timeSaved = Loc.tr("TTS", "analytics.time_saved", fallback: "Time Saved")
      /// Total Characters
      public static let totalCharacters = Loc.tr("TTS", "analytics.total_characters", fallback: "Total Characters")
      /// Total Duration
      public static let totalDuration = Loc.tr("TTS", "analytics.total_duration", fallback: "Total Duration")
      /// Total Sessions
      public static let totalSessions = Loc.tr("TTS", "analytics.total_sessions", fallback: "Total Sessions")
    }
    public enum EnglishAccents {
      /// American
      public static let american = Loc.tr("TTS", "english_accents.american", fallback: "American")
      /// Australian
      public static let australian = Loc.tr("TTS", "english_accents.australian", fallback: "Australian")
      /// Belgian
      public static let belgian = Loc.tr("TTS", "english_accents.belgian", fallback: "Belgian")
      /// British
      public static let british = Loc.tr("TTS", "english_accents.british", fallback: "British")
      /// Canadian
      public static let canadian = Loc.tr("TTS", "english_accents.canadian", fallback: "Canadian")
      /// Indian
      public static let indian = Loc.tr("TTS", "english_accents.indian", fallback: "Indian")
      /// Irish
      public static let irish = Loc.tr("TTS", "english_accents.irish", fallback: "Irish")
      /// Singaporean
      public static let singaporean = Loc.tr("TTS", "english_accents.singaporean", fallback: "Singaporean")
      /// South African
      public static let southAfrican = Loc.tr("TTS", "english_accents.south_african", fallback: "South African")
    }
    public enum Filters {
      /// All Accents
      public static let allAccents = Loc.tr("TTS", "filters.all_accents", fallback: "All Accents")
      /// All Ages
      public static let allAges = Loc.tr("TTS", "filters.all_ages", fallback: "All Ages")
      /// All Genders
      public static let allGenders = Loc.tr("TTS", "filters.all_genders", fallback: "All Genders")
      /// All Languages
      public static let allLanguages = Loc.tr("TTS", "filters.all_languages", fallback: "All Languages")
      /// All Timbres
      public static let allTimbres = Loc.tr("TTS", "filters.all_timbres", fallback: "All Timbres")
      /// All Use Cases
      public static let allUseCases = Loc.tr("TTS", "filters.all_use_cases", fallback: "All Use Cases")
      /// Available Voices
      public static let availableVoices = Loc.tr("TTS", "filters.available_voices", fallback: "Available Voices")
      /// Filters
      public static let filters = Loc.tr("TTS", "filters.filters", fallback: "Filters")
      /// No voices available
      public static let noVoicesAvailable = Loc.tr("TTS", "filters.no_voices_available", fallback: "No voices available")
      /// No voices found
      public static let noVoicesFound = Loc.tr("TTS", "filters.no_voices_found", fallback: "No voices found")
      /// Try adjusting your search or filters
      public static let noVoicesFoundMessage = Loc.tr("TTS", "filters.no_voices_found_message", fallback: "Try adjusting your search or filters")
      /// Reset
      public static let reset = Loc.tr("TTS", "filters.reset", fallback: "Reset")
      /// Select Voice
      public static let selectVoice = Loc.tr("TTS", "filters.select_voice", fallback: "Select Voice")
    }
    public enum Models {
      /// English
      public static let english = Loc.tr("TTS", "models.english", fallback: "English")
      /// Speechify's English text-to-speech model offers standard capabilities designed to deliver clear and natural voice output for reading texts. The model focuses on delivering a consistent user experience.
      public static let englishDescription = Loc.tr("TTS", "models.english_description", fallback: "Speechify's English text-to-speech model offers standard capabilities designed to deliver clear and natural voice output for reading texts. The model focuses on delivering a consistent user experience.")
      /// Multilingual
      public static let multilingual = Loc.tr("TTS", "models.multilingual", fallback: "Multilingual")
      /// Multilingual model allows the usage of all supported languages and supports using multiple languages within a single sentence. The audio output of this model is distinctively different from other models.
      public static let multilingualDescription = Loc.tr("TTS", "models.multilingual_description", fallback: "Multilingual model allows the usage of all supported languages and supports using multiple languages within a single sentence. The audio output of this model is distinctively different from other models.")
    }
    public enum Settings {
      /// Dashboard
      public static let dashboard = Loc.tr("TTS", "settings.dashboard", fallback: "Dashboard")
      /// Speechify
      public static let speechify = Loc.tr("TTS", "settings.speechify", fallback: "Speechify")
      /// Speechify's Text-to-Speech AI model is available for all users as a premium feature. It allows you to choose from a wide range of voices and accents, so you can fine-tune your study experience.
      public static let speechifyDescription = Loc.tr("TTS", "settings.speechify_description", fallback: "Speechify's Text-to-Speech AI model is available for all users as a premium feature. It allows you to choose from a wide range of voices and accents, so you can fine-tune your study experience.")
      /// Speechify's Text-to-Speech AI model is included in your subscription.
      public static let speechifyProDescription = Loc.tr("TTS", "settings.speechify_pro_description", fallback: "Speechify's Text-to-Speech AI model is included in your subscription.")
      /// Text-to-Speech
      public static let textToSpeech = Loc.tr("TTS", "settings.text_to_speech", fallback: "Text-to-Speech")
    }
    public enum Usage {
      /// Monthly Limit
      public static let monthlyLimit = Loc.tr("TTS", "usage.monthly_limit", fallback: "Monthly Limit")
      /// Monthly Limit Exceeded
      public static let monthlyLimitExceeded = Loc.tr("TTS", "usage.monthly_limit_exceeded", fallback: "Monthly Limit Exceeded")
      /// You have reached your monthly limit of 50,000 characters for Speechify TTS. Please try again next month or use Google TTS instead.
      public static let monthlyLimitExceededMessage = Loc.tr("TTS", "usage.monthly_limit_exceeded_message", fallback: "You have reached your monthly limit of 50,000 characters for Speechify TTS. Please try again next month or use Google TTS instead.")
      /// Monthly Usage
      public static let monthlyUsage = Loc.tr("TTS", "usage.monthly_usage", fallback: "Monthly Usage")
      /// Remaining Characters
      public static let remainingCharacters = Loc.tr("TTS", "usage.remaining_characters", fallback: "Remaining Characters")
    }
  }
  public enum Words {
    /// Add example
    public static let addExample = Loc.tr("Words", "add_example", fallback: "Add example")
    /// Add idiom
    public static let addIdiom = Loc.tr("Words", "add_idiom", fallback: "Add idiom")
    /// Add More Words
    public static let addMoreWords = Loc.tr("Words", "add_more_words", fallback: "Add More Words")
    /// Add new idiom
    public static let addNewIdiom = Loc.tr("Words", "add_new_idiom", fallback: "Add new idiom")
    /// Add New Word
    public static let addNewWord = Loc.tr("Words", "add_new_word", fallback: "Add New Word")
    /// Add notes...
    public static let addNotes = Loc.tr("Words", "add_notes", fallback: "Add notes...")
    /// Add Tag
    public static let addTag = Loc.tr("Words", "add_tag", fallback: "Add Tag")
    /// Add this idiom by tapping on the button above
    public static let addThisIdiom = Loc.tr("Words", "add_this_idiom", fallback: "Add this idiom by tapping on the button above")
    /// Add to Shared Dictionary
    public static let addToSharedDictionary = Loc.tr("Words", "add_to_shared_dictionary", fallback: "Add to Shared Dictionary")
    /// Add Word
    public static let addWord = Loc.tr("Words", "add_word", fallback: "Add Word")
    /// Add Your First Word
    public static let addYourFirstWord = Loc.tr("Words", "add_your_first_word", fallback: "Add Your First Word")
    /// All idioms
    public static let allIdioms = Loc.tr("Words", "all_idioms", fallback: "All idioms")
    /// All meanings
    public static let allMeanings = Loc.tr("Words", "all_meanings", fallback: "All meanings")
    /// All Words
    public static let allWords = Loc.tr("Words", "all_words", fallback: "All Words")
    /// Alphabetically
    public static let alphabetically = Loc.tr("Words", "alphabetically", fallback: "Alphabetically")
    /// Begin to add idioms to your list by tapping on plus icon in upper left corner
    public static let beginAddIdioms = Loc.tr("Words", "begin_add_idioms", fallback: "Begin to add idioms to your list by tapping on plus icon in upper left corner")
    /// By Part of Speech
    public static let byPartOfSpeech = Loc.tr("Words", "by_part_of_speech", fallback: "By Part of Speech")
    /// Create Tags
    public static let createTags = Loc.tr("Words", "create_tags", fallback: "Create Tags")
    /// Definition
    public static let definition = Loc.tr("Words", "definition", fallback: "Definition")
    /// Delete idiom
    public static let deleteIdiom = Loc.tr("Words", "delete_idiom", fallback: "Delete idiom")
    /// Are you sure you want to delete this idiom?
    public static let deleteIdiomConfirmation = Loc.tr("Words", "delete_idiom_confirmation", fallback: "Are you sure you want to delete this idiom?")
    /// Delete Meaning
    public static let deleteMeaning = Loc.tr("Words", "delete_meaning", fallback: "Delete Meaning")
    /// Are you sure you want to delete this meaning?
    public static let deleteMeaningConfirmation = Loc.tr("Words", "delete_meaning_confirmation", fallback: "Are you sure you want to delete this meaning?")
    /// Delete Word
    public static let deleteWord = Loc.tr("Words", "delete_word", fallback: "Delete Word")
    /// Are you sure you want to delete this word?
    public static let deleteWordConfirmation = Loc.tr("Words", "delete_word_confirmation", fallback: "Are you sure you want to delete this word?")
    /// Difficulty
    public static let difficulty = Loc.tr("Words", "difficulty", fallback: "Difficulty")
    /// Earliest First
    public static let earliestFirst = Loc.tr("Words", "earliest_first", fallback: "Earliest First")
    /// Edit example
    public static let editExample = Loc.tr("Words", "edit_example", fallback: "Edit example")
    /// Edit meaning
    public static let editMeaning = Loc.tr("Words", "edit_meaning", fallback: "Edit meaning")
    /// Enter definition
    public static let enterDefinition = Loc.tr("Words", "enter_definition", fallback: "Enter definition")
    /// There is an error loading definitions. Please try again.
    public static let errorLoadingDefinitions = Loc.tr("Words", "error_loading_definitions", fallback: "There is an error loading definitions. Please try again.")
    /// Example
    public static let example = Loc.tr("Words", "example", fallback: "Example")
    /// Examples
    public static let examples = Loc.tr("Words", "examples", fallback: "Examples")
    /// Favorite
    public static let favorite = Loc.tr("Words", "favorite", fallback: "Favorite")
    /// Favorite Idioms
    public static let favoriteIdioms = Loc.tr("Words", "favorite_idioms", fallback: "Favorite Idioms")
    /// Favorite Words
    public static let favoriteWords = Loc.tr("Words", "favorite_words", fallback: "Favorite Words")
    /// Favorites
    public static let favorites = Loc.tr("Words", "favorites", fallback: "Favorites")
    /// Filter
    public static let filter = Loc.tr("Words", "filter", fallback: "Filter")
    /// Found
    public static let found = Loc.tr("Words", "found", fallback: "Found")
    /// Found
    public static let foundIdioms = Loc.tr("Words", "found_idioms", fallback: "Found")
    /// Idiom
    public static let idiom = Loc.tr("Words", "idiom", fallback: "Idiom")
    /// Idioms
    public static let idioms = Loc.tr("Words", "idioms", fallback: "Idioms")
    /// Impressive Vocabulary!
    public static let impressiveVocabulary = Loc.tr("Words", "impressive_vocabulary", fallback: "Impressive Vocabulary!")
    /// You've built a collection of **%d words**! Your dedication to learning is inspiring.
    public static func impressiveVocabularyMessage(_ p1: Int) -> String {
      return Loc.tr("Words", "impressive_vocabulary_message", p1, fallback: "You've built a collection of **%d words**! Your dedication to learning is inspiring.")
    }
    /// In Progress
    public static let inProgress = Loc.tr("Words", "in_progress", fallback: "In Progress")
    /// Input Language
    public static let inputLanguage = Loc.tr("Words", "input_language", fallback: "Input Language")
    /// Language
    public static let language = Loc.tr("Words", "language", fallback: "Language")
    /// Latest First
    public static let latestFirst = Loc.tr("Words", "latest_first", fallback: "Latest First")
    /// Mastered
    public static let mastered = Loc.tr("Words", "mastered", fallback: "Mastered")
    /// Mastered Words
    public static let masteredWords = Loc.tr("Words", "mastered_words", fallback: "Mastered Words")
    /// Meaning
    public static let meaning = Loc.tr("Words", "meaning", fallback: "Meaning")
    /// Meaning played
    public static let meaningPlayed = Loc.tr("Words", "meaning_played", fallback: "Meaning played")
    /// Meaning removed
    public static let meaningRemoved = Loc.tr("Words", "meaning_removed", fallback: "Meaning removed")
    /// Meaning removal canceled
    public static let meaningRemovingCanceled = Loc.tr("Words", "meaning_removing_canceled", fallback: "Meaning removal canceled")
    /// Meaning updated
    public static let meaningUpdated = Loc.tr("Words", "meaning_updated", fallback: "Meaning updated")
    /// Meanings
    public static let meanings = Loc.tr("Words", "meanings", fallback: "Meanings")
    /// Needs Review
    public static let needsReview = Loc.tr("Words", "needs_review", fallback: "Needs Review")
    /// New
    public static let new = Loc.tr("Words", "new", fallback: "New")
    /// New definition
    public static let newDefinition = Loc.tr("Words", "new_definition", fallback: "New definition")
    /// New Words
    public static let newWords = Loc.tr("Words", "new_words", fallback: "New Words")
    /// No definition
    public static let noDefinition = Loc.tr("Words", "no_definition", fallback: "No definition")
    /// No examples yet
    public static let noExamplesYet = Loc.tr("Words", "no_examples_yet", fallback: "No examples yet")
    /// No idioms found
    public static let noIdiomsFound = Loc.tr("Words", "no_idioms_found", fallback: "No idioms found")
    /// No notes
    public static let noNotes = Loc.tr("Words", "no_notes", fallback: "No notes")
    /// No tags added yet.
    public static let noTagsAddedYet = Loc.tr("Words", "no_tags_added_yet", fallback: "No tags added yet.")
    /// No tags selected
    public static let noTagsSelected = Loc.tr("Words", "no_tags_selected", fallback: "No tags selected")
    /// No transcription
    public static let noTranscription = Loc.tr("Words", "no_transcription", fallback: "No transcription")
    /// Notes
    public static let notes = Loc.tr("Words", "notes", fallback: "Notes")
    /// Notes updated
    public static let notesUpdated = Loc.tr("Words", "notes_updated", fallback: "Notes updated")
    /// Part Of Speech
    public static let partOfSpeech = Loc.tr("Words", "part_of_speech", fallback: "Part Of Speech")
    /// Private Dictionary
    public static let privateDictionary = Loc.tr("Words", "private_dictionary", fallback: "Private Dictionary")
    /// Pronunciation
    public static let pronunciation = Loc.tr("Words", "pronunciation", fallback: "Pronunciation")
    /// Quiz-based
    public static let quizBased = Loc.tr("Words", "quiz_based", fallback: "Quiz-based")
    /// Score
    public static let score = Loc.tr("Words", "score", fallback: "Score")
    /// Search
    public static let search = Loc.tr("Words", "search", fallback: "Search")
    /// Search idioms...
    public static let searchIdioms = Loc.tr("Words", "search_idioms", fallback: "Search idioms...")
    /// Search Results
    public static let searchResults = Loc.tr("Words", "search_results", fallback: "Search Results")
    /// Search words...
    public static let searchWords = Loc.tr("Words", "search_words", fallback: "Search words...")
    /// Select a definition
    public static let selectDefinition = Loc.tr("Words", "select_definition", fallback: "Select a definition")
    /// Shared Dictionary
    public static let sharedDictionary = Loc.tr("Words", "shared_dictionary", fallback: "Shared Dictionary")
    /// Show all meanings
    public static let showAllMeanings = Loc.tr("Words", "show_all_meanings", fallback: "Show all meanings")
    /// Sort
    public static let sort = Loc.tr("Words", "sort", fallback: "Sort")
    /// Tag
    public static let tag = Loc.tr("Words", "tag", fallback: "Tag")
    /// Tagged Words
    public static let taggedWords = Loc.tr("Words", "tagged_words", fallback: "Tagged Words")
    /// Tags
    public static let tags = Loc.tr("Words", "tags", fallback: "Tags")
    /// Transcription
    public static let transcription = Loc.tr("Words", "transcription", fallback: "Transcription")
    /// Translating definitions...
    public static let translatingDefinitions = Loc.tr("Words", "translating_definitions", fallback: "Translating definitions...")
    /// Translating word...
    public static let translatingWord = Loc.tr("Words", "translating_word", fallback: "Translating word...")
    /// Type an example here
    public static let typeExampleHere = Loc.tr("Words", "type_example_here", fallback: "Type an example here")
    /// Type new example here...
    public static let typeNewExampleHere = Loc.tr("Words", "type_new_example_here", fallback: "Type new example here...")
    /// Type a word
    public static let typeWord = Loc.tr("Words", "type_word", fallback: "Type a word")
    /// Type a word and press 'Search' to find its definitions
    public static let typeWordAndPressSearch = Loc.tr("Words", "type_word_and_press_search", fallback: "Type a word and press 'Search' to find its definitions")
    /// Type the word here...
    public static let typeWordHere = Loc.tr("Words", "type_word_here", fallback: "Type the word here...")
    /// Word
    public static let word = Loc.tr("Words", "word", fallback: "Word")
    /// Word Details
    public static let wordDetails = Loc.tr("Words", "word_details", fallback: "Word Details")
    /// Words
    public static let words = Loc.tr("Words", "words", fallback: "Words")
    /// Words In Progress
    public static let wordsInProgress = Loc.tr("Words", "words_in_progress", fallback: "Words In Progress")
    /// Words Needing Review
    public static let wordsNeedingReview = Loc.tr("Words", "words_needing_review", fallback: "Words Needing Review")
    public enum Difficulty {
      /// In Progress
      public static let inProgress = Loc.tr("Words", "difficulty.in_progress", fallback: "In Progress")
      /// Mastered
      public static let mastered = Loc.tr("Words", "difficulty.mastered", fallback: "Mastered")
      /// Needs Review
      public static let needsReview = Loc.tr("Words", "difficulty.needs_review", fallback: "Needs Review")
      /// New
      public static let new = Loc.tr("Words", "difficulty.new", fallback: "New")
    }
    public enum EmptyStates {
      /// No Favorite Words
      public static let noFavoriteWords = Loc.tr("Words", "empty_states.no_favorite_words", fallback: "No Favorite Words")
      /// No Idioms Yet
      public static let noIdiomsYet = Loc.tr("Words", "empty_states.no_idioms_yet", fallback: "No Idioms Yet")
      /// No Search Results
      public static let noSearchResults = Loc.tr("Words", "empty_states.no_search_results", fallback: "No Search Results")
      /// No Words Yet
      public static let noWordsYet = Loc.tr("Words", "empty_states.no_words_yet", fallback: "No Words Yet")
      /// Start improving your vocabulary by adding your first idiom
      public static let startImprovingVocabulary = Loc.tr("Words", "empty_states.start_improving_vocabulary", fallback: "Start improving your vocabulary by adding your first idiom")
      /// Tap the heart icon on any idiom to add it to your favorites
      public static let tapHeartIconToAddFavorites = Loc.tr("Words", "empty_states.tap_heart_icon_to_add_favorites", fallback: "Tap the heart icon on any idiom to add it to your favorites")
      /// Try a different search term or add a new idiom
      public static let tryDifferentSearchTerm = Loc.tr("Words", "empty_states.try_different_search_term", fallback: "Try a different search term or add a new idiom")
    }
    public enum InputLanguage {
      /// Auto Detect
      public static let autoDetect = Loc.tr("Words", "input_language.auto_detect", fallback: "Auto Detect")
    }
    public enum PartOfSpeech {
      public enum Full {
        /// Adjective
        public static let adjective = Loc.tr("Words", "part_of_speech.full.adjective", fallback: "Adjective")
        /// Adverb
        public static let adverb = Loc.tr("Words", "part_of_speech.full.adverb", fallback: "Adverb")
        /// Conjunction
        public static let conjunction = Loc.tr("Words", "part_of_speech.full.conjunction", fallback: "Conjunction")
        /// Exclamation
        public static let exclamation = Loc.tr("Words", "part_of_speech.full.exclamation", fallback: "Exclamation")
        /// Idiom
        public static let idiom = Loc.tr("Words", "part_of_speech.full.idiom", fallback: "Idiom")
        /// Interjection
        public static let interjection = Loc.tr("Words", "part_of_speech.full.interjection", fallback: "Interjection")
        /// Noun
        public static let noun = Loc.tr("Words", "part_of_speech.full.noun", fallback: "Noun")
        /// Phrase
        public static let phrase = Loc.tr("Words", "part_of_speech.full.phrase", fallback: "Phrase")
        /// Preposition
        public static let preposition = Loc.tr("Words", "part_of_speech.full.preposition", fallback: "Preposition")
        /// Pronoun
        public static let pronoun = Loc.tr("Words", "part_of_speech.full.pronoun", fallback: "Pronoun")
        /// Unknown
        public static let unknown = Loc.tr("Words", "part_of_speech.full.unknown", fallback: "Unknown")
        /// Verb
        public static let verb = Loc.tr("Words", "part_of_speech.full.verb", fallback: "Verb")
      }
      public enum Short {
        /// Adj.
        public static let adjective = Loc.tr("Words", "part_of_speech.short.adjective", fallback: "Adj.")
        /// Adv.
        public static let adverb = Loc.tr("Words", "part_of_speech.short.adverb", fallback: "Adv.")
        /// Conj.
        public static let conjunction = Loc.tr("Words", "part_of_speech.short.conjunction", fallback: "Conj.")
        /// Excl.
        public static let exclamation = Loc.tr("Words", "part_of_speech.short.exclamation", fallback: "Excl.")
        /// Idiom
        public static let idiom = Loc.tr("Words", "part_of_speech.short.idiom", fallback: "Idiom")
        /// Interj.
        public static let interjection = Loc.tr("Words", "part_of_speech.short.interjection", fallback: "Interj.")
        /// Noun
        public static let noun = Loc.tr("Words", "part_of_speech.short.noun", fallback: "Noun")
        /// Phrase
        public static let phrase = Loc.tr("Words", "part_of_speech.short.phrase", fallback: "Phrase")
        /// Prep.
        public static let preposition = Loc.tr("Words", "part_of_speech.short.preposition", fallback: "Prep.")
        /// Pron.
        public static let pronoun = Loc.tr("Words", "part_of_speech.short.pronoun", fallback: "Pron.")
        /// Unkn.
        public static let unknown = Loc.tr("Words", "part_of_speech.short.unknown", fallback: "Unkn.")
        /// Verb
        public static let verb = Loc.tr("Words", "part_of_speech.short.verb", fallback: "Verb")
      }
    }
    public enum Sorting {
      /// Alphabetically
      public static let alphabetically = Loc.tr("Words", "sorting.alphabetically", fallback: "Alphabetically")
      /// By Part of Speech
      public static let byPartOfSpeech = Loc.tr("Words", "sorting.by_part_of_speech", fallback: "By Part of Speech")
      /// Earliest first
      public static let earliestFirst = Loc.tr("Words", "sorting.earliest_first", fallback: "Earliest first")
      /// Latest first
      public static let latestFirst = Loc.tr("Words", "sorting.latest_first", fallback: "Latest first")
    }
    public enum WordDetails {
      /// Add example
      public static let addExample = Loc.tr("Words", "word_details.add_example", fallback: "Add example")
      /// Definition
      public static let definition = Loc.tr("Words", "word_details.definition", fallback: "Definition")
      /// Delete failed
      public static let deleteFailed = Loc.tr("Words", "word_details.delete_failed", fallback: "Delete failed")
      /// Delete word
      public static let deleteWord = Loc.tr("Words", "word_details.delete_word", fallback: "Delete word")
      /// Difficulty
      public static let difficulty = Loc.tr("Words", "word_details.difficulty", fallback: "Difficulty")
      /// Edit example
      public static let editExample = Loc.tr("Words", "word_details.edit_example", fallback: "Edit example")
      /// Example
      public static let example = Loc.tr("Words", "word_details.example", fallback: "Example")
      /// Examples
      public static let examples = Loc.tr("Words", "word_details.examples", fallback: "Examples")
      /// Part of Speech
      public static let partOfSpeech = Loc.tr("Words", "word_details.part_of_speech", fallback: "Part of Speech")
      /// Transcription
      public static let transcription = Loc.tr("Words", "word_details.transcription", fallback: "Transcription")
      /// Type an example here
      public static let typeExampleHere = Loc.tr("Words", "word_details.type_example_here", fallback: "Type an example here")
    }
    public enum WordList {
      /// All Words
      public static let allWords = Loc.tr("Words", "word_list.all_words", fallback: "All Words")
      /// Favorite
      public static let favorite = Loc.tr("Words", "word_list.favorite", fallback: "Favorite")
      /// Manage Tags
      public static let manageTags = Loc.tr("Words", "word_list.manage_tags", fallback: "Manage Tags")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Loc {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
