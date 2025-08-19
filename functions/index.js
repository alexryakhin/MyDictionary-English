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
        const { word, maxDefinitions, targetLanguage, userId } = req.body;
        
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
                    content: buildWordInformationPrompt(word, maxDefinitions || 5, targetLanguage || 'English')
                }
            ],
            temperature: 0.3,
            max_tokens: 500
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

// Helper function to build the prompt
function buildWordInformationPrompt(word, maxDefinitions, targetLanguage) {
    return `Provide information for the word '${word}' in ${targetLanguage} in the following JSON format:

{
  "pronunciation": "[phonetic pronunciation]",
  "definitions": [
    {
      "partOfSpeech": "[Part of Speech in English]",
      "definition": "[1-3 sentence definition in ${targetLanguage}]",
      "examples": [
        "[1-2 sentence example in the language of the input word]",
        "[1-2 sentence example in the language of the input word]"
      ]
    }
  ]
}

IMPORTANT RULES:
1. Return ONLY valid JSON - no additional text before or after
2. Definition must be in the ${targetLanguage}. Examples should be in the language of the input word.
3. Pronunciation should be of the original input word using International Phonetic Alphabet
4. If the input word is in a different language, provide definition in the ${targetLanguage}, but do not translate the word.
5. Keep definitions concise (1-3 sentences) and examples practical (1-2 sentences each)
6. Include the most common meanings first
7. Provide up to ${maxDefinitions} definitions
8. Each definition should have 2-3 examples
9. Use proper JSON escaping for quotes and special characters`;
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


