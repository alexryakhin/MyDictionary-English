const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.addCollaborator = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { dictionaryId, email, role } = data;
    
    // Validate input
    if (!dictionaryId || !email || !role) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }
    
    if (!['editor', 'viewer'].includes(role)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid role. Must be "editor" or "viewer"');
    }
    
    try {
        const db = admin.firestore();
        
        // Get the dictionary to check permissions
        const dictionaryRef = db.collection('dictionaries').doc(dictionaryId);
        const dictionaryDoc = await dictionaryRef.get();
        
        if (!dictionaryDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Dictionary not found');
        }
        
        const dictionaryData = dictionaryDoc.data();
        
        // Check if the current user can edit this dictionary
        const currentUserId = context.auth.uid;
        const canEdit = dictionaryData.owner === currentUserId || 
                       dictionaryData.collaborators?.[currentUserId] === 'editor';
        
        if (!canEdit) {
            throw new functions.https.HttpsError('permission-denied', 'You do not have permission to add collaborators');
        }
        
        // Find user by email
        let targetUser;
        try {
            targetUser = await admin.auth().getUserByEmail(email);
        } catch (error) {
            throw new functions.https.HttpsError('not-found', 'User with this email not found');
        }
        
        // Check if user is trying to add themselves
        if (targetUser.uid === currentUserId) {
            throw new functions.https.HttpsError('invalid-argument', 'Cannot add yourself as a collaborator');
        }
        
        // Add collaborator to dictionary
        await dictionaryRef.update({
            [`collaborators.${targetUser.uid}`]: role
        });
        
        // Log the action
        console.log(`User ${currentUserId} added ${targetUser.uid} as ${role} to dictionary ${dictionaryId}`);
        
        return { success: true, message: 'Collaborator added successfully' };
        
    } catch (error) {
        console.error('Error adding collaborator:', error);
        
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        
        throw new functions.https.HttpsError('internal', 'Failed to add collaborator');
    }
});

exports.removeCollaborator = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { dictionaryId, userId } = data;
    
    // Validate input
    if (!dictionaryId || !userId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }
    
    try {
        const db = admin.firestore();
        const dictionaryRef = db.collection('dictionaries').doc(dictionaryId);
        const dictionaryDoc = await dictionaryRef.get();
        
        if (!dictionaryDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Dictionary not found');
        }
        
        const dictionaryData = dictionaryDoc.data();
        const currentUserId = context.auth.uid;
        
        // Only the owner can remove collaborators
        if (dictionaryData.owner !== currentUserId) {
            throw new functions.https.HttpsError('permission-denied', 'Only the owner can remove collaborators');
        }
        
        // Check if user is trying to remove themselves
        if (userId === currentUserId) {
            throw new functions.https.HttpsError('invalid-argument', 'Cannot remove yourself as the owner');
        }
        
        // Remove collaborator from dictionary
        await dictionaryRef.update({
            [`collaborators.${userId}`]: admin.firestore.FieldValue.delete()
        });
        
        // Log the action
        console.log(`User ${currentUserId} removed ${userId} from dictionary ${dictionaryId}`);
        
        return { success: true, message: 'Collaborator removed successfully' };
        
    } catch (error) {
        console.error('Error removing collaborator:', error);
        
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        
        throw new functions.https.HttpsError('internal', 'Failed to remove collaborator');
    }
});

exports.onUserDelete = functions.auth.user().onDelete(async (user) => {
    const db = admin.firestore();
    
    try {
        // Find all dictionaries where the user is a collaborator
        const dictionaries = await db.collection('dictionaries')
            .where(`collaborators.${user.uid}`, '!=', null)
            .get();
        
        const batch = db.batch();
        
        // Remove user from all dictionaries they're collaborating on
        dictionaries.forEach(doc => {
            batch.update(doc.ref, {
                [`collaborators.${user.uid}`]: admin.firestore.FieldValue.delete()
            });
        });
        
        await batch.commit();
        
        console.log(`Removed user ${user.uid} from ${dictionaries.size} dictionaries`);
        
    } catch (error) {
        console.error('Error removing user from dictionaries:', error);
    }
});

exports.cleanupOrphanedDictionaries = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const db = admin.firestore();
    
    try {
        // Find dictionaries with no collaborators (orphaned)
        const dictionaries = await db.collection('dictionaries').get();
        
        const batch = db.batch();
        let deletedCount = 0;
        
        for (const doc of dictionaries.docs) {
            const data = doc.data();
            const collaborators = data.collaborators || {};
            
            // If dictionary has no collaborators and no owner, mark for deletion
            if (Object.keys(collaborators).length === 0 && !data.owner) {
                batch.delete(doc.ref);
                deletedCount++;
            }
        }
        
        if (deletedCount > 0) {
            await batch.commit();
            console.log(`Deleted ${deletedCount} orphaned dictionaries`);
        }
        
    } catch (error) {
        console.error('Error cleaning up orphaned dictionaries:', error);
    }
}); 