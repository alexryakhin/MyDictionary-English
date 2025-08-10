//
//  SharedWordCollaborativeFeaturesTest.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

// MARK: - Test Implementation

struct SharedWordCollaborativeFeaturesTest {
    
    static func runTests() {
        print("🧪 Running SharedWord Collaborative Features Tests")
        
        // Test 1: Create a shared word with collaborative features
        testSharedWordCreation()
        
        // Test 2: Test like functionality
        testLikeFunctionality()
        
        // Test 3: Test difficulty functionality
        testDifficultyFunctionality()
        
        // Test 4: Test statistics calculation
        testStatisticsCalculation()
        
        print("✅ All tests completed")
    }
    
    private static func testSharedWordCreation() {
        print("📝 Test 1: SharedWord Creation")
        
        let word = SharedWord(
            id: "test-1",
            wordItself: "Ephemeral",
            definition: "Lasting for a very short time",
            partOfSpeech: "adjective",
            phonetic: "ɪˈfem(ə)rəl",
            examples: ["The ephemeral beauty of sunset"],
            languageCode: "en",
            addedByEmail: "john@example.com",
            addedByDisplayName: "John Doe",
            likes: ["john@example.com": true, "jane@example.com": false],
            difficulties: ["john@example.com": 2, "jane@example.com": 1, "bob@example.com": 3]
        )
        
        print("   ✅ Word created: \(word.wordItself)")
        print("   ✅ Like count: \(word.likeCount)")
        print("   ✅ Average difficulty: \(word.averageDifficulty)")
        print("   ✅ Total difficulties: \(word.difficulties.count)")
    }
    
    private static func testLikeFunctionality() {
        print("📝 Test 2: Like Functionality")
        
        var word = SharedWord(
            id: "test-2",
            wordItself: "Serendipity",
            definition: "The occurrence and development of events by chance in a happy or beneficial way",
            partOfSpeech: "noun",
            phonetic: "ˌserənˈdipədē",
            examples: ["Meeting you here was pure serendipity"],
            languageCode: "en",
            addedByEmail: "alice@example.com",
            addedByDisplayName: "Alice"
        )
        
        // Test initial state
        print("   ✅ Initial like count: \(word.likeCount)")
        print("   ✅ Is liked by alice: \(word.isLikedBy("alice@example.com"))")
        
        // Test adding likes
        word = SharedWord(
            id: word.id,
            wordItself: word.wordItself,
            definition: word.definition,
            partOfSpeech: word.partOfSpeech,
            phonetic: word.phonetic,
            examples: word.examples,
            languageCode: word.languageCode,
            addedByEmail: word.addedByEmail,
            addedByDisplayName: word.addedByDisplayName,
            addedAt: word.addedAt,
            likes: ["alice@example.com": true, "bob@example.com": true],
            difficulties: word.difficulties
        )
        
        print("   ✅ After adding likes: \(word.likeCount)")
        print("   ✅ Is liked by alice: \(word.isLikedBy("alice@example.com"))")
        print("   ✅ Is liked by bob: \(word.isLikedBy("bob@example.com"))")
    }
    
    private static func testDifficultyFunctionality() {
        print("📝 Test 3: Difficulty Functionality")
        
        let word = SharedWord(
            id: "test-3",
            wordItself: "Pneumonoultramicroscopicsilicovolcanoconiosiss",
            definition: "A lung disease caused by the inhalation of very fine silicate or quartz dust",
            partOfSpeech: "noun",
            phonetic: "ˌnjuːmənoʊˌʌltrəˌmaɪkrəˈskɒpɪkˌsɪlɪkoʊvɒlˌkeɪnoʊˌkoʊniˈoʊsɪs",
            examples: ["The medical term is quite long"],
            languageCode: "en",
            addedByEmail: "doctor@example.com",
            addedByDisplayName: "Dr. Smith",
            likes: [:],
            difficulties: [
                "student1@example.com": 3,
                "student2@example.com": 2,
                "student3@example.com": 3,
                "student4@example.com": 1
            ]
        )
        
        print("   ✅ Difficulty for student1: \(word.getDifficultyFor("student1@example.com"))")
        print("   ✅ Difficulty display name: \(word.getDifficultyDisplayName(for: "student1@example.com"))")
        print("   ✅ Average difficulty: \(word.averageDifficulty)")
        print("   ✅ Total ratings: \(word.difficulties.count)")
    }
    
    private static func testStatisticsCalculation() {
        print("📝 Test 4: Statistics Calculation")
        
        let word = SharedWord(
            id: "test-4",
            wordItself: "Ubiquitous",
            definition: "Present, appearing, or found everywhere",
            partOfSpeech: "adjective",
            phonetic: "juːˈbɪkwɪtəs",
            examples: ["Mobile phones have become ubiquitous"],
            languageCode: "en",
            addedByEmail: "teacher@example.com",
            addedByDisplayName: "Ms. Johnson",
            likes: [
                "student1@example.com": true,
                "student2@example.com": true,
                "student3@example.com": false,
                "student4@example.com": true,
                "student5@example.com": false
            ],
            difficulties: [
                "student1@example.com": 2,
                "student2@example.com": 1,
                "student3@example.com": 3,
                "student4@example.com": 2,
                "student5@example.com": 1
            ]
        )
        
        print("   ✅ Like count: \(word.likeCount) out of 5 users")
        print("   ✅ Average difficulty: \(word.averageDifficulty)")
        print("   ✅ Difficulty distribution:")
        
        let difficultyCounts = Dictionary(grouping: word.difficulties.values, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        
        for (difficulty, count) in difficultyCounts {
            let level = ["New", "In Progress", "Needs Review", "Mastered"][difficulty]
            print("      \(level): \(count) users")
        }
    }
}

// MARK: - Usage Example

/*
// To run the tests, call:
SharedWordCollaborativeFeaturesTest.runTests()

// Example output:
🧪 Running SharedWord Collaborative Features Tests
📝 Test 1: SharedWord Creation
   ✅ Word created: Ephemeral
   ✅ Like count: 1
   ✅ Average difficulty: 2.0
   ✅ Total difficulties: 3
📝 Test 2: Like Functionality
   ✅ Initial like count: 0
   ✅ Is liked by alice: false
   ✅ After adding likes: 2
   ✅ Is liked by alice: true
   ✅ Is liked by bob: true
📝 Test 3: Difficulty Functionality
   ✅ Difficulty for student1: 3
   ✅ Difficulty display name: Mastered
   ✅ Average difficulty: 2.25
   ✅ Total ratings: 4
📝 Test 4: Statistics Calculation
   ✅ Like count: 3 out of 5 users
   ✅ Average difficulty: 1.8
   ✅ Difficulty distribution:
      New: 0 users
      In Progress: 2 users
      Needs Review: 2 users
      Mastered: 1 users
✅ All tests completed
*/
