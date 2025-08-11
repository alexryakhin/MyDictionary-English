const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Firebase Function to send push notifications
 * Triggered by HTTP request from the iOS app
 */
exports.sendNotification = functions
    .region('europe-west3')
    .https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    
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
exports.onCollaboratorAdded = functions
    .region('europe-west3')
    .firestore
    .document('dictionaries/{dictionaryId}/collaborators/{email}')
    .onCreate(async (snap, context) => {
        const collaboratorData = snap.data();
        const { dictionaryId, email } = context.params;
        
        console.log('New collaborator added:', { dictionaryId, email, collaboratorData });
        
        try {
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
            
            // Get user's FCM token - try both email and userId as document ID
            let fcmToken = null;
            
            // First try with email as document ID
            const userDocByEmail = await admin.firestore()
                .collection('users')
                .doc(email)
                .get();
                
            if (userDocByEmail.exists) {
                fcmToken = userDocByEmail.data().fcmToken;
                console.log('Found FCM token using email as document ID');
            }
            
            // If not found, try to find user by email in a different way
            if (!fcmToken) {
                // Query users collection to find user by email field
                const usersQuery = await admin.firestore()
                    .collection('users')
                    .where('email', '==', email)
                    .limit(1)
                    .get();
                    
                if (!usersQuery.empty) {
                    const userDoc = usersQuery.docs[0];
                    fcmToken = userDoc.data().fcmToken;
                    console.log('Found FCM token using email field query');
                }
            }
            
            if (!fcmToken) {
                console.log('No FCM token found for user:', email);
                return;
            }
            
            // Send notification
            const message = {
                token: fcmToken,
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
            
            const response = await admin.messaging().send(message);
            console.log('Successfully sent collaborator invitation notification:', response);
            
        } catch (error) {
            console.error('Error sending collaborator invitation notification:', error);
        }
    });
