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

/**
 * Secure OpenAI Proxy Function
 * Protects API key and provides usage control
 */
exports.openAIProxy = onRequest({
    region: 'europe-west3',
    cors: true,
    secrets: ['OPENAI_API_KEY', 'OPENAI_ORGANIZATION', 'OPENAI_PROJECT_ID']
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }
    
    try {
        const { word, maxDefinitions, inputLanguage, userLanguage, userId } = req.body;
        
        // Validate required fields
        if (!word || !userId) {
            res.status(400).json({
                success: false,
                error: 'Missing required fields: word, userId'
            });
            return;
        }
        
        // Get OpenAI API key from environment (secure)
        const openAIKey = process.env.OPENAI_API_KEY;
        if (!openAIKey) {
            console.error('OpenAI API key not configured');
            res.status(500).json({
                success: false,
                error: 'OpenAI service not configured'
            });
            return;
        }
        
        // Check user's usage limits (optional - implement based on your subscription model)
        const userUsage = await checkUserUsage(userId);
        if (!userUsage.allowed) {
            res.status(429).json({
                success: false,
                error: 'Usage limit exceeded',
                limit: userUsage.limit,
                used: userUsage.used
            });
            return;
        }
        
        // Build OpenAI request
        const openAIRequest = {
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: "You are a helpful vocabulary learning assistant. Provide clear, concise, and educational responses in JSON format."
                },
                {
                    role: "user",
                    content: buildWordInformationPrompt(word, maxDefinitions || 5, inputLanguage || 'English', userLanguage || 'English')
                }
            ],
            temperature: 0.3,
            max_tokens: 2000
        };
        
        // Make request to OpenAI
        const openAIResponse = await axios.post('https://api.openai.com/v1/chat/completions', openAIRequest, {
            headers: {
                'Authorization': `Bearer ${openAIKey}`,
                'Content-Type': 'application/json',
                'OpenAI-Organization': process.env.OPENAI_ORGANIZATION || '',
                'OpenAI-Project': process.env.OPENAI_PROJECT_ID || ''
            }
        });
        
        const content = openAIResponse.data.choices[0]?.message?.content || '';
        const usage = openAIResponse.data.usage;
        
        // Log usage for analytics
        await logUsage(userId, word, usage);
        
        // Return response to client
        res.status(200).json({
            success: true,
            data: content,
            usage: {
                promptTokens: usage.prompt_tokens,
                completionTokens: usage.completion_tokens,
                totalTokens: usage.total_tokens
            }
        });
        
    } catch (error) {
        console.error('OpenAI proxy error:', error.response?.data || error.message);
        
        if (error.response?.status === 429) {
            res.status(429).json({
                success: false,
                error: 'OpenAI rate limit exceeded'
            });
        } else if (error.response?.status === 401) {
            res.status(500).json({
                success: false,
                error: 'OpenAI authentication failed'
            });
        } else {
            res.status(500).json({
                success: false,
                error: 'OpenAI service error'
            });
        }
    }
});

/**
 * Synthesize speech with selected voice
 */
exports.synthesizeSpeech = onRequest({
    region: 'europe-west3',
    cors: true,
    secrets: ['SPEECHIFY_API_KEY']
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }
    
    try {
        const { text, voice, language, model, audioFormat, userId } = req.body;
        
        // Validate required fields
        if (!text || !userId) {
            res.status(400).json({
                success: false,
                error: 'Missing required fields: text, userId'
            });
            return;
        }
        
        // Validate text length (Speechify has limits)
        if (text.length > 5000) {
            res.status(400).json({
                success: false,
                error: 'Text too long. Maximum 5000 characters allowed.'
            });
            return;
        }
        
        const speechifyApiKey = process.env.SPEECHIFY_API_KEY;
        if (!speechifyApiKey) {
            console.error('Speechify API key not configured');
            res.status(500).json({
                success: false,
                error: 'Speechify service not configured'
            });
            return;
        }
        
        // Check user's usage limits (optional - implement based on your subscription model)
        const userUsage = await checkUserSpeechUsage(userId);
        if (!userUsage.allowed) {
            res.status(429).json({
                success: false,
                error: 'Speech synthesis limit exceeded',
                limit: userUsage.limit,
                used: userUsage.used
            });
            return;
        }
        
        // Prepare request body using the correct format from Swift implementation
        const speechifyRequest = {
            input: text,
            voice_id: voice || "en-US-1", // Default voice
            audio_format: audioFormat || "mp3",
            language: language || "en-US",
            model: model || "simba-english" // Default to English model
        };
        
        // Synthesize speech with Speechify API using the correct URL
        const response = await axios.post('https://api.sws.speechify.com/v1/audio/speech', speechifyRequest, {
            headers: {
                'Authorization': `Bearer ${speechifyApiKey}`,
                'Content-Type': 'application/json'
            }
        });
        
        // The response should contain audio_data as base64 string
        const responseData = response.data;
        
        if (!responseData.audio_data) {
            throw new Error('No audio data in response');
        }
        
        // Log usage for analytics
        await logSpeechUsage(userId, text, voice);
        
        res.status(200).json({
            success: true,
            audioData: responseData.audio_data,
            format: responseData.audio_format || audioFormat || "mp3",
            voice: voice,
            billableCharacters: responseData.billable_characters_count,
            textLength: text.length
        });
        
    } catch (error) {
        console.error('Speechify synthesize error:', error.response?.data || error.message);
        
        if (error.response?.status === 401) {
            res.status(500).json({
                success: false,
                error: 'Speechify authentication failed'
            });
        } else if (error.response?.status === 402 || error.response?.status === 403) {
            res.status(403).json({
                success: false,
                error: 'Speechify premium feature required'
            });
        } else if (error.response?.status === 429) {
            res.status(429).json({
                success: false,
                error: 'Speechify rate limit exceeded'
            });
        } else if (error.response?.status === 400) {
            res.status(400).json({
                success: false,
                error: 'Invalid request to Speechify API'
            });
        } else {
            res.status(500).json({
                success: false,
                error: 'Speechify service error'
            });
        }
    }
});

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
18. CRITICAL: Definitions should NOT mention the input word itself - they should explain the concept without using the word being defined (this is essential for quiz functionality)`;
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

// Helper function to check user speech usage limits
async function checkUserSpeechUsage(userId) {
    try {
        // Get user's subscription status and speech usage
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();
            
        if (!userDoc.exists) {
            return { allowed: true, limit: 100, used: 0 }; // Default for new users
        }
        
        const userData = userDoc.data();
        const subscription = userData.subscription || 'free';
        const monthlySpeechUsage = userData.monthlySpeechUsage || 0;
        
        // Define speech limits based on subscription
        const limits = {
            free: 50,
            pro: 500,
            unlimited: -1 // No limit
        };
        
        const limit = limits[subscription] || 50;
        
        if (limit === -1) {
            return { allowed: true, limit: -1, used: monthlySpeechUsage };
        }
        
        return {
            allowed: monthlySpeechUsage < limit,
            limit: limit,
            used: monthlySpeechUsage
        };
        
    } catch (error) {
        console.error('Error checking user speech usage:', error);
        return { allowed: true, limit: 100, used: 0 }; // Allow by default if error
    }
}

// Helper function to log speech usage
async function logSpeechUsage(userId, text, voice) {
    try {
        const batch = admin.firestore().batch();
        
        // Update user's monthly speech usage
        const userRef = admin.firestore().collection('users').doc(userId);
        batch.update(userRef, {
            monthlySpeechUsage: admin.firestore.FieldValue.increment(1),
            lastSpeechActivity: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Log detailed speech usage for analytics
        const usageRef = admin.firestore().collection('speech_usage').doc();
        batch.set(usageRef, {
            userId: userId,
            text: text.substring(0, 100) + (text.length > 100 ? '...' : ''), // Truncate for storage
            voice: voice,
            textLength: text.length,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        
        await batch.commit();
        
    } catch (error) {
        console.error('Error logging speech usage:', error);
    }
}


