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
 * Debug function to check user devices and send test notifications
 */
exports.debugUserDevices = functions
    .region('europe-west3')
    .https
    .onCall(async (data, context) => {
        // Check if user is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        
        const userEmail = context.auth.token.email;
        console.log('Debug request for user:', userEmail);
        
        try {
            // Get user's active device tokens
            const devicesSnapshot = await admin.firestore()
                .collection('users')
                .doc(userEmail)
                .collection('devices')
                .where('isActive', '==', true)
                .get();
                
            const devices = [];
            devicesSnapshot.forEach(doc => {
                const deviceData = doc.data();
                devices.push({
                    deviceId: doc.id,
                    token: deviceData.id,
                    platform: deviceData.platform,
                    appVersion: deviceData.appVersion,
                    lastUpdated: deviceData.lastUpdated?.toDate(),
                    isActive: deviceData.isActive
                });
            });
            
            console.log(`Found ${devices.length} active devices for user:`, userEmail);
            
            // Send test notification if requested
            if (data.sendTestNotification && devices.length > 0) {
                const deviceTokens = devices.map(d => d.token);
                
                const message = {
                    notification: {
                        title: 'Debug Test Notification',
                        body: `This is a test notification sent at ${new Date().toISOString()}`
                    },
                    data: {
                        type: 'debug_test',
                        timestamp: Date.now().toString()
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
                
                const response = await admin.messaging().sendMulticast({
                    tokens: deviceTokens,
                    ...message
                });
                
                console.log('Test notification sent:', {
                    successCount: response.successCount,
                    failureCount: response.failureCount,
                    totalTokens: deviceTokens.length
                });
                
                return {
                    devices: devices,
                    testNotification: {
                        sent: true,
                        successCount: response.successCount,
                        failureCount: response.failureCount
                    }
                };
            }
            
            return {
                devices: devices,
                testNotification: { sent: false }
            };
            
        } catch (error) {
            console.error('Error in debugUserDevices:', error);
            throw new functions.https.HttpsError('internal', 'Failed to debug user devices');
        }
    });

/**
 * Debug function to check collaborator invitation flow
 */
exports.debugCollaboratorInvitation = functions
    .region('europe-west3')
    .https
    .onCall(async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        
        const { dictionaryId, collaboratorEmail } = data;
        
        if (!dictionaryId || !collaboratorEmail) {
            throw new functions.https.HttpsError('invalid-argument', 'dictionaryId and collaboratorEmail are required');
        }
        
        console.log('Debug collaborator invitation:', { dictionaryId, collaboratorEmail });
        
        try {
            // Check if dictionary exists
            const dictionaryDoc = await admin.firestore()
                .collection('dictionaries')
                .doc(dictionaryId)
                .get();
                
            if (!dictionaryDoc.exists) {
                return { error: 'Dictionary not found' };
            }
            
            const dictionaryName = dictionaryDoc.data().name || 'Unknown Dictionary';
            
            // Check if collaborator document exists
            const collaboratorDoc = await admin.firestore()
                .collection('dictionaries')
                .doc(dictionaryId)
                .collection('collaborators')
                .doc(collaboratorEmail)
                .get();
                
            if (!collaboratorDoc.exists) {
                return { error: 'Collaborator document not found' };
            }
            
            // Check user's devices
            const devicesSnapshot = await admin.firestore()
                .collection('users')
                .doc(collaboratorEmail)
                .collection('devices')
                .where('isActive', '==', true)
                .get();
                
            const deviceTokens = devicesSnapshot.docs.map(doc => doc.data().id);
            
            return {
                dictionary: {
                    id: dictionaryId,
                    name: dictionaryName,
                    exists: true
                },
                collaborator: {
                    email: collaboratorEmail,
                    exists: true,
                    data: collaboratorDoc.data()
                },
                devices: {
                    count: deviceTokens.length,
                    tokens: deviceTokens
                }
            };
            
        } catch (error) {
            console.error('Error in debugCollaboratorInvitation:', error);
            throw new functions.https.HttpsError('internal', 'Failed to debug collaborator invitation');
        }
    });
