const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const axios = require('axios');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Firebase Function to send push notifications
 * Triggered by HTTP request from the iOS app
 */
exports.sendNotification = onRequest({
    region: 'europe-west3',
    cors: true
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }
    
    try {
        const { token, title, body, data } = req.body;
        
        if (!token || !title || !body) {
            res.status(400).send('Missing required fields: token, title, body');
            return;
        }
        
        const message = {
            token: token,
            notification: {
                title: title,
                body: body
            },
            data: data || {},
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1
                    }
                }
            }
        };
        
        const response = await admin.messaging().send(message);
        console.log('Successfully sent notification:', response);
        
        res.status(200).json({
            success: true,
            messageId: response
        });
        
    } catch (error) {
        console.error('Error sending notification:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * Firebase Function triggered when a collaborator is added to a dictionary
 * This is an alternative approach using Firestore triggers
 */
exports.onCollaboratorAdded = onDocumentCreated({
    region: 'europe-west3',
    document: 'dictionaries/{dictionaryId}/collaborators/{email}'
}, async (event) => {
    const snap = event.data;
    const context = event.context;
    
    if (!snap) {
        console.log('No data associated with the event');
        return;
    }
    
    const collaboratorData = snap.data();
    const { dictionaryId, email } = context.params;
    
    console.log('New collaborator added:', { dictionaryId, email, collaboratorData });
    
    try {
        // Check if this is the owner being added (skip notification for owner)
        const role = collaboratorData.role || 'collaborator';
        if (role === 'owner') {
            console.log('Skipping notification for dictionary owner:', email);
            return;
        }
        
        // Get the dictionary name
        const dictionaryDoc = await admin.firestore()
            .collection('dictionaries')
            .doc(dictionaryId)
            .get();
            
        if (!dictionaryDoc.exists) {
            console.log('Dictionary not found:', dictionaryId);
            return;
        }
        
        const dictionaryName = dictionaryDoc.data().name || 'Unknown Dictionary';
        
        // Get user's active device tokens
        const devicesSnapshot = await admin.firestore()
            .collection('users')
            .doc(email)
            .collection('devices')
            .where('isActive', '==', true)
            .get();
            
        if (devicesSnapshot.empty) {
            console.log('No active devices found for user:', email);
            return;
        }
        
        const deviceTokens = devicesSnapshot.docs.map(doc => doc.data().id);
        console.log(`Found ${deviceTokens.length} active device tokens for user:`, email);
        
        // Send notification to all active devices
        const message = {
            notification: {
                title: 'New Dictionary Invitation',
                body: `You've been added to '${dictionaryName}'`
            },
            data: {
                type: 'collaborator_invitation',
                dictionaryId: dictionaryId,
                dictionaryName: dictionaryName
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1
                    }
                }
            }
        };
        
        // Send to each token individually
        let successCount = 0;
        let failureCount = 0;
        const failedTokens = [];
        
        for (const token of deviceTokens) {
            try {
                await admin.messaging().send({
                    token: token,
                    ...message
                });
                successCount++;
                console.log(`✅ Successfully sent notification to token: ${token.substring(0, 20)}...`);
            } catch (error) {
                failureCount++;
                failedTokens.push(token);
                console.log(`❌ Failed to send notification to token: ${token.substring(0, 20)}...`, error.message);
                
                // Mark failed token as inactive
                const failedDevice = devicesSnapshot.docs.find(doc => doc.data().id === token);
                if (failedDevice) {
                    await failedDevice.ref.update({
                        isActive: false,
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
            }
        }
        
        console.log('Collaborator invitation notifications completed:', {
            successCount: successCount,
            failureCount: failureCount,
            totalTokens: deviceTokens.length
        });
        
    } catch (error) {
        console.error('Error sending collaborator invitation notification:', error);
    }
});


// Helper function to clean JSON responses
function cleanJSONResponse(response) {
    if (!response || typeof response !== 'string') {
        return response;
    }
    
    let cleaned = response.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    
    cleaned = cleaned.trim();
    
    // Try to fix common JSON issues
    try {
        // First, try to parse as-is
        JSON.parse(cleaned);
        return cleaned;
    } catch (error) {
        console.log('JSON parsing failed, attempting to fix...');
        
        // Count braces and brackets to see if we're missing closing ones
        const openBraces = (cleaned.match(/\{/g) || []).length;
        const closeBraces = (cleaned.match(/\}/g) || []).length;
        const openBrackets = (cleaned.match(/\[/g) || []).length;
        const closeBrackets = (cleaned.match(/\]/g) || []).length;
        
        // Add missing closing braces
        if (openBraces > closeBraces) {
            cleaned += '}'.repeat(openBraces - closeBraces);
        }
        
        // Add missing closing brackets
        if (openBrackets > closeBrackets) {
            cleaned += ']'.repeat(openBrackets - closeBrackets);
        }
        
        // Try parsing again
        try {
            JSON.parse(cleaned);
            console.log('Successfully fixed JSON by adding missing braces/brackets');
            return cleaned;
        } catch (secondError) {
            console.log('Still failed to parse JSON after fixing braces');
            
            // If still failing, try to extract the JSON part
            const jsonStart = cleaned.indexOf('{');
            if (jsonStart !== -1) {
                const jsonPart = cleaned.substring(jsonStart);
                try {
                    JSON.parse(jsonPart);
                    console.log('Successfully extracted JSON part');
                    return jsonPart;
                } catch (thirdError) {
                    console.log('Failed to extract valid JSON part');
                }
            }
            
            // Return original if all attempts fail
            console.log('Returning original response as fallback');
            return response;
        }
    }
}

// Helper function to build the prompt
function buildWordInformationPrompt(word, maxDefinitions, inputLanguage, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. User's language is ${userLanguage}, and he/she learns ${inputLanguage}. Provide comprehensive information for the word/phrase '${word}' in ${userLanguage} and examples in ${inputLanguage} in the following JSON format:

{
  "pronunciation": "[phonetic pronunciation]",
  "definitions": [
    {
      "partOfSpeech": "[Part of Speech in English]",
      "definition": "[1-3 sentence definition in ${userLanguage}]",
              "examples": [
          "[1-2 sentence example in ${inputLanguage}]",
          "[1-2 sentence example in ${inputLanguage}]"
        ]
    }
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Definition must be in the ${userLanguage}. Examples must be in ${inputLanguage}.
3. Part of speech should be chosen from: 'noun', 'verb', 'adjective', 'adverb', 'conjunction', 'pronoun', 'preposition', 'exclamation', 'interjection', 'idiom', 'phrase', 'unknown'.
4. Pronunciation should be of the original input word using International Phonetic Alphabet
5. Focus on COMMON, EVERYDAY meanings and uses first, not just religious or specialized meanings
6. Include different meanings and contexts - avoid repetitive definitions that mean the same thing
7. For phrases and expressions, include both literal and figurative meanings
8. Include idiomatic uses, slang, and colloquial expressions when applicable
9. Keep definitions concise (1-3 sentences) and examples practical (1-2 sentences each)
10. Provide up to ${maxDefinitions} distinct definitions
11. Each definition should have 2-3 examples
12. Use proper JSON escaping for quotes and special characters
13. If the word/phrase has multiple distinct meanings, prioritize the most commonly used ones in everyday language
14. For religious names/phrases, also include their use as exclamations, expressions of surprise, or in casual speech
15. Include both formal and informal usage contexts
16. As this is for educational purposes, include ALL meanings including slang, profanity, and informal expressions when they exist
17. Provide accurate linguistic information regardless of content sensitivity - this helps language learners understand real-world usage
18. CRITICAL: Definitions should NOT mention the input word itself - they should explain the concept without using the word being defined (this is essential for quiz functionality), but examples should include the word so a student will see a real usage.`;
}

// Helper function to check user usage limits
async function checkUserUsage(userId) {
    try {
        // Get user's subscription status and usage
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();
            
        if (!userDoc.exists) {
            return { allowed: true, limit: 100, used: 0 }; // Default for new users
        }
        
        const userData = userDoc.data();
        const subscription = userData.subscription || 'free';
        const monthlyUsage = userData.monthlyUsage || 0;
        
        // Define limits based on subscription
        const limits = {
            free: 50,
            pro: 1000,
            unlimited: -1 // No limit
        };
        
        const limit = limits[subscription] || 50;
        
        if (limit === -1) {
            return { allowed: true, limit: -1, used: monthlyUsage };
        }
        
        return {
            allowed: monthlyUsage < limit,
            limit: limit,
            used: monthlyUsage
        };
        
    } catch (error) {
        console.error('Error checking user usage:', error);
        return { allowed: true, limit: 100, used: 0 }; // Allow by default if error
    }
}

// Helper function to log usage
async function logUsage(userId, word, usage) {
    try {
        const batch = admin.firestore().batch();
        
        // Update user's monthly usage
        const userRef = admin.firestore().collection('users').doc(userId);
        batch.update(userRef, {
            monthlyUsage: admin.firestore.FieldValue.increment(usage.total_tokens),
            lastAIActivity: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Log detailed usage for analytics
        const usageRef = admin.firestore().collection('ai_usage').doc();
        batch.set(usageRef, {
            userId: userId,
            word: word,
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens,
            totalTokens: usage.total_tokens,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        
        await batch.commit();
        
    } catch (error) {
        console.error('Error logging usage:', error);
    }
}

/**
 * Check if a nickname is available
 */
exports.checkNicknameAvailability = onRequest({
    region: 'europe-west3',
    cors: true
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }
    
    try {
        const { nickname, userId } = req.body;
        
        if (!nickname || !userId) {
            res.status(400).json({
                success: false,
                error: 'Missing required fields: nickname, userId'
            });
            return;
        }
        
        // Validate nickname format
        const nicknameRegex = /^[a-z0-9_]+$/;
        if (!nicknameRegex.test(nickname.toLowerCase())) {
            res.status(400).json({
                success: false,
                error: 'Invalid nickname format. Only lowercase letters, numbers, and underscores are allowed.'
            });
            return;
        }
        
        // Check if nickname is already taken
        const snapshot = await admin.firestore()
            .collection('users')
            .where('nickname', '==', nickname.toLowerCase())
            .limit(1)
            .get();
        
        const isAvailable = snapshot.empty;
        
        res.status(200).json({
            success: true,
            isAvailable: isAvailable,
            nickname: nickname.toLowerCase()
        });
        
    } catch (error) {
        console.error('Error checking nickname availability:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to check nickname availability'
        });
    }
});

/**
 * Search for a user by nickname or email
 */
exports.searchUser = onRequest({
    region: 'europe-west3',
    cors: true
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }
    
    try {
        const { query, searchType, userId } = req.body;
        
        if (!query || !searchType || !userId) {
            res.status(400).json({
                success: false,
                error: 'Missing required fields: query, searchType, userId'
            });
            return;
        }
        
        if (!['nickname', 'email'].includes(searchType)) {
            res.status(400).json({
                success: false,
                error: 'Invalid searchType. Must be "nickname" or "email"'
            });
            return;
        }
        
        // Search for user
        const snapshot = await admin.firestore()
            .collection('users')
            .where(searchType, '==', searchType === 'nickname' ? query.toLowerCase() : query.toLowerCase())
            .limit(1)
            .get();
        
        if (snapshot.empty) {
            res.status(200).json({
                success: true,
                user: null
            });
            return;
        }
        
        const userDoc = snapshot.docs[0];
        const userData = userDoc.data();
        
        // Return only necessary user information for security
        const userInfo = {
            id: userDoc.id,
            email: userData.email,
            displayName: userData.name || userData.displayName,
            nickname: userData.nickname,
            registrationDate: userData.registrationDate
        };
        
        res.status(200).json({
            success: true,
            user: userInfo
        });
        
    } catch (error) {
        console.error('Error searching user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to search user'
        });
    }
});


// Helper function to build sentence evaluation prompt
function buildSentenceEvaluationPrompt(sentence, targetWord, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Evaluate the given sentence for correct usage of the target word.

Target Word: ${targetWord}
Sentence: ${sentence}
User Language: ${userLanguage}

Evaluate the sentence and provide feedback in ${userLanguage} in the following JSON format:

{
  "usageScore": [0-100 score for correct word usage and meaning],
  "grammarScore": [0-100 score for grammar and syntax],
  "overallScore": [0-100 overall score combining usage and grammar],
  "feedback": "[2-3 sentence detailed feedback explaining the evaluation in ${userLanguage}]",
  "isCorrect": [true if overall score >= 60, false otherwise],
  "suggestions": [
    "[specific suggestion for improvement in ${userLanguage}]",
    "[another suggestion if applicable in ${userLanguage}]"
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Usage score focuses on whether the word is used correctly in context
3. Grammar score focuses on sentence structure and syntax
4. Overall score should be a weighted average (usage 70%, grammar 30%)
5. Feedback should be educational and constructive in ${userLanguage}
6. isCorrect should be true if the word is used correctly (overall score >= 60)
7. Suggestions should be specific and actionable in ${userLanguage}
8. Use proper JSON escaping for quotes and special characters
9. Be encouraging but honest about mistakes
10. Consider context, meaning, and natural language usage
11. All feedback and suggestions must be in ${userLanguage}`;
}

// Helper function to build context question prompt
function buildContextQuestionPrompt(word, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple choice question to test understanding of word usage in context.

Target Word: ${word}
User Language: ${userLanguage}

Create a question with 4 options in the following JSON format:

{
  "word": "${word}",
  "question": "Choose the sentence where '${word}' is used correctly:",
  "options": [
    {
      "text": "[sentence using the word incorrectly or in wrong context]",
      "isCorrect": false,
      "explanation": "[brief explanation of why this usage is incorrect]"
    },
    {
      "text": "[sentence using the word correctly]",
      "isCorrect": true,
      "explanation": "[brief explanation of why this usage is correct]"
    },
    {
      "text": "[sentence using the word incorrectly or in wrong context]",
      "isCorrect": false,
      "explanation": "[brief explanation of why this usage is incorrect]"
    },
    {
      "text": "[sentence using the word incorrectly or in wrong context]",
      "isCorrect": false,
      "explanation": "[brief explanation of why this usage is incorrect]"
    }
  ],
  "correctOptionIndex": [1-based index of the correct option],
  "explanation": "[detailed explanation of the correct answer and why other options are wrong in ${userLanguage}]"
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Only ONE option should be correct (isCorrect: true)
3. Incorrect options should show common mistakes or wrong contexts
4. Sentences should be natural and realistic
5. correctOptionIndex should be 1, 2, 3, or 4 (1-based indexing)
6. Explanations should be educational and clear in ${userLanguage}
7. Use proper JSON escaping for quotes and special characters
8. Make the question challenging but fair
9. Consider different meanings and contexts of the word
10. Ensure the correct answer is clearly the best choice
11. The explanation must be provided in ${userLanguage}`;
}

// Helper function to build fill-in-the-blank story prompt
function buildFillInTheBlankStoryPrompt(word, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a short story with a blank that should be filled with the target word.

Target Word: ${word}
User Language: ${userLanguage}

Create a story in the following JSON format:

{
  "word": "${word}",
  "story": "[short story (2-3 sentences) with a blank space where the word should go. Use '___' to represent the blank]",
  "blankPosition": [position of the blank in the story (1-based)],
  "context": "[brief explanation of the story context and why the word fits in ${userLanguage}]",
  "hint": "[helpful hint about the word's meaning or usage in ${userLanguage}]",
  "isCorrect": true,
  "feedback": "[feedback message for when the word is correctly filled in in ${userLanguage}]"
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Story should be engaging and provide clear context for the word
3. The blank should be in a natural position where the word makes sense
4. Use '___' to represent the blank space
5. blankPosition should indicate which blank (if multiple) contains the target word
6. Context should explain why this word fits in this story in ${userLanguage}
7. Hint should be helpful but not give away the answer in ${userLanguage}
8. Use proper JSON escaping for quotes and special characters
9. Story should be appropriate for language learning
10. The word should be the best choice for the blank
11. All feedback, hints, and context explanations must be in ${userLanguage}`;
}

// Helper function to build batch sentences evaluation prompt
function buildSentencesEvaluationPrompt(sentences, userLanguage) {
    const sentencesList = sentences.map((item, index) => 
        `${index + 1}. Target Word: '${item.targetWord}' | Sentence: '${item.sentence}'`
    ).join('\n');
    
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Evaluate the given sentences for correct usage of their target words.

User Language: ${userLanguage}

Sentences to evaluate:
${sentencesList}

Evaluate each sentence and provide feedback in ${userLanguage} in the following JSON format:

{
  "evaluations": [
    {
      "targetWord": "${sentences[0].targetWord}",
      "sentence": "${sentences[0].sentence}",
      "usageScore": [0-100 score for correct word usage and meaning],
      "grammarScore": [0-100 score for grammar and syntax],
      "overallScore": [0-100 overall score combining usage and grammar],
      "feedback": "[2-3 sentence detailed feedback explaining the evaluation in ${userLanguage}]",
      "isCorrect": [true if overall score >= 60, false otherwise],
      "suggestions": [
        "[specific suggestion for improvement in ${userLanguage}]",
        "[another suggestion if applicable in ${userLanguage}]"
      ]
    }
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Evaluate each sentence independently
3. Usage score focuses on whether the word is used correctly in context
4. Grammar score focuses on sentence structure and syntax
5. Overall score should be a weighted average (usage 70%, grammar 30%)
6. Feedback should be educational and constructive in ${userLanguage}
7. isCorrect should be true if the word is used correctly (overall score >= 60)
8. Suggestions should be specific and actionable in ${userLanguage}
9. Use proper JSON escaping for quotes and special characters
10. Be encouraging but honest about mistakes
11. Consider context, meaning, and natural language usage
12. All feedback and suggestions must be in ${userLanguage}`;
}

// Helper function to build batch context questions prompt
function buildContextQuestionsPrompt(words, userLanguage) {
    const wordsList = words.map((word, index) => 
        `${index + 1}. '${word}'`
    ).join('\n');
    
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create multiple choice questions to test understanding of word usage in context.

User Language: ${userLanguage}

Words to create questions for:
${wordsList}

Create one question per word with 4 options in the following JSON format:

{
  "questions": [
    {
      "word": "${words[0]}",
      "question": "Choose the sentence where '${words[0]}' is used correctly:",
      "options": [
        {
          "text": "[sentence using the word incorrectly or in wrong context]",
          "isCorrect": false,
          "explanation": "[brief explanation of why this usage is incorrect]"
        },
        {
          "text": "[sentence using the word correctly]",
          "isCorrect": true,
          "explanation": "[brief explanation of why this usage is correct]"
        },
        {
          "text": "[sentence using the word incorrectly or in wrong context]",
          "isCorrect": false,
          "explanation": "[brief explanation of why this usage is incorrect]"
        },
        {
          "text": "[sentence using the word incorrectly or in wrong context]",
          "isCorrect": false,
          "explanation": "[brief explanation of why this usage is incorrect]"
        }
      ],
      "correctOptionIndex": [1-based index of the correct option],
      "explanation": "[detailed explanation of the correct answer and why other options are wrong in ${userLanguage}]"
    }
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Create one question per word in the order provided
3. Only ONE option should be correct (isCorrect: true) per question
4. Incorrect options should show common mistakes or wrong contexts
5. Sentences should be natural and realistic
6. correctOptionIndex should be 1, 2, 3, or 4 (1-based indexing)
7. Explanations should be educational and clear in ${userLanguage}
8. Use proper JSON escaping for quotes and special characters
9. Make the questions challenging but fair
10. Consider different meanings and contexts of each word
11. Ensure the correct answer is clearly the best choice
12. The explanation must be provided in ${userLanguage}`;
}

// Helper function to build single context question prompt
function buildSingleContextQuestionPrompt(word, wordLanguage, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple choice question to test understanding of word usage in context.

Word Language: ${wordLanguage}
User Language: ${userLanguage}

Word to create question for: '${word}' (in ${wordLanguage})

Create one question with 4 options in the following JSON format:

{
  "question": {
    "word": "${word}",
    "question": "Choose the sentence where '${word}' is used correctly:",
    "options": [
      {
        "text": "[sentence in ${wordLanguage} using the word incorrectly or in wrong context]",
        "isCorrect": false,
        "explanation": "[brief explanation of why this usage is incorrect in ${userLanguage}]"
      },
      {
        "text": "[sentence in ${wordLanguage} using the word correctly]",
        "isCorrect": true,
        "explanation": "[brief explanation of why this usage is correct in ${userLanguage}]"
      },
      {
        "text": "[sentence in ${wordLanguage} using the word incorrectly or in wrong context]",
        "isCorrect": false,
        "explanation": "[brief explanation of why this usage is incorrect in ${userLanguage}]"
      },
      {
        "text": "[sentence in ${wordLanguage} using the word incorrectly or in wrong context]",
        "isCorrect": false,
        "explanation": "[brief explanation of why this usage is incorrect in ${userLanguage}]"
      }
    ],
    "correctOptionIndex": [1-based index of the correct option],
    "explanation": "[detailed explanation of the correct answer and why other options are wrong in ${userLanguage}]"
  }
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Only ONE option should be correct (isCorrect: true)
3. All sentences must be in ${wordLanguage} (the word's language)
4. Only explanations should be in ${userLanguage} (the user's language)
5. Incorrect options should show common mistakes or wrong contexts in ${wordLanguage}
6. Sentences should be natural and realistic in ${wordLanguage}
7. correctOptionIndex should be 1, 2, 3, or 4 (1-based indexing)
8. Explanations should be educational and clear in ${userLanguage}
9. Use proper JSON escaping for quotes and special characters
10. Make the question challenging but fair
11. Consider different meanings and contexts of the word in ${wordLanguage}
12. Ensure the correct answer is clearly the best choice`;
}

// Helper function to build single fill-in-the-blank story prompt
function buildSingleFillInTheBlankStoryPrompt(word, wordLanguage, userLanguage) {
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple-choice fill-in-the-blank story for vocabulary practice.

Word Language: ${wordLanguage}
User Language: ${userLanguage}

Word to create story for: '${word}' (in ${wordLanguage})

Create one story in the following JSON format:

{
  "story": {
    "word": "${word}",
    "story": "[short story in ${wordLanguage} (2-3 sentences) with a blank space where the word should go. Use '___' to represent the blank]",
    "options": [
      {
        "text": "[correct word/phrase in ${wordLanguage}]",
        "isCorrect": true,
        "explanation": "[explanation of why this is correct in ${userLanguage}]"
      },
      {
        "text": "[incorrect option 1 in ${wordLanguage}]",
        "isCorrect": false,
        "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
      },
      {
        "text": "[incorrect option 2 in ${wordLanguage}]",
        "isCorrect": false,
        "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
      },
      {
        "text": "[incorrect option 3 in ${wordLanguage}]",
        "isCorrect": false,
        "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
      }
    ],
    "correctOptionIndex": [1-based index of the correct option],
    "explanation": "[overall explanation of the story and correct answer in ${userLanguage}]"
  }
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Provide exactly 4 options: 1 correct and 3 incorrect
3. correctOptionIndex should be 1-based (1, 2, 3, or 4)
4. All story content and options must be in ${wordLanguage} (the word's language)
5. Only explanations should be in ${userLanguage} (the user's language)
6. Incorrect options should be plausible but clearly wrong in ${wordLanguage}
7. Each option should have a clear explanation in ${userLanguage}
8. Story should be appropriate for language learning
9. The correct word should be the best choice for the blank
10. Use proper JSON escaping for quotes and special characters`;
}

// Helper function to build batch fill-in-the-blank stories prompt
function buildFillInTheBlankStoriesPrompt(words, userLanguage) {
    const wordsList = words.map((word, index) => 
        `${index + 1}. '${word}'`
    ).join('\n');
    
    return `IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create multiple-choice fill-in-the-blank stories for vocabulary practice.

User Language: ${userLanguage}

Words to create stories for:
${wordsList}

Create one story per word in the following JSON format:

{
  "stories": [
    {
      "word": "${words[0]}",
      "story": "[short story (2-3 sentences) with a blank space where the word should go. Use '___' to represent the blank]",
      "options": [
        {
          "text": "[correct word/phrase]",
          "isCorrect": true,
          "explanation": "[explanation of why this is correct in ${userLanguage}]"
        },
        {
          "text": "[incorrect option 1]",
          "isCorrect": false,
          "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
        },
        {
          "text": "[incorrect option 2]",
          "isCorrect": false,
          "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
        },
        {
          "text": "[incorrect option 3]",
          "isCorrect": false,
          "explanation": "[explanation of why this is incorrect in ${userLanguage}]"
        }
      ],
      "correctOptionIndex": 1,
      "explanation": "[overall explanation of the story and correct answer in ${userLanguage}]"
    }
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Create one story per word in the order provided
3. Story should be engaging and provide clear context for the word
4. The blank should be in a natural position where the word makes sense
5. Use '___' to represent the blank space
6. Provide exactly 4 options: 1 correct and 3 incorrect
7. correctOptionIndex should be 1-based (1, 2, 3, or 4)
8. Incorrect options should be plausible but clearly wrong
9. Each option should have a clear explanation
10. Story should be appropriate for language learning
11. The correct word should be the best choice for the blank
12. All explanations must be in ${userLanguage}
13. Use proper JSON escaping for quotes and special characters`;
}


