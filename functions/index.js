const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Set the region for all functions
const region = "europe-west3";

exports.addCollaborator = functions.https.onCall({ region }, async (request) => {
  console.log('🔍 [addCollaborator] Function called with request:', request);
  console.log('🔍 [addCollaborator] Auth:', request.auth);
  console.log('🔍 [addCollaborator] Data:', request.data);

  // ✅ Check authentication
  if (!request.auth) {
    console.log('❌ [addCollaborator] No authentication found');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const currentUserId = request.auth.uid;
  console.log('✅ [addCollaborator] User authenticated:', currentUserId);

  const { dictionaryId, email, role } = request.data;

  // 🛠 Validate input
  if (!dictionaryId || !email || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  if (!['editor', 'viewer'].includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid role. Must be "editor" or "viewer"'
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid email format');
  }

  try {
    const db = admin.firestore();
    const dictionaryRef = db.collection('dictionaries').doc(dictionaryId);
    const dictionaryDoc = await dictionaryRef.get();

    // 🔐 Check dictionary existence
    if (!dictionaryDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Dictionary not found');
    }

    const dictionaryData = dictionaryDoc.data();

    // 🔐 Check owner permission
    if (dictionaryData.owner !== currentUserId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only the owner can add collaborators'
      );
    }

    // Ensure collaborators field exists
    if (!dictionaryData.collaborators) {
      await dictionaryRef.update({ collaborators: {} });
    }

    // 🎯 Lookup user by email
    let targetUser;
    try {
      targetUser = await admin.auth().getUserByEmail(email);
    } catch (error) {
      throw new functions.https.HttpsError('not-found', 'User with this email not found');
    }

    // ⛔ Prevent self-adding
    if (targetUser.uid === currentUserId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Cannot add yourself as a collaborator'
      );
    }

    // ✅ Add collaborator with transaction to handle concurrency
    await db.runTransaction(async (transaction) => {
      const updatedDoc = await transaction.get(dictionaryRef);
      if (!updatedDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Dictionary not found');
      }
      transaction.update(dictionaryRef, {
        [`collaborators.${targetUser.uid}`]: role,
      });
    });

    console.log(
      `✅ [addCollaborator] User ${currentUserId} added ${targetUser.uid} as ${role} to dictionary ${dictionaryId}`
    );

    return { success: true, message: 'Collaborator added successfully' };
  } catch (error) {
    console.error('❌ [addCollaborator] Error:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to add collaborator');
  }
});

exports.removeCollaborator = functions.https.onCall({ region }, async (request) => {
  console.log('🔍 [removeCollaborator] Function called with request:', request);
  console.log('🔍 [removeCollaborator] Auth:', request.auth);
  console.log('🔍 [removeCollaborator] Data:', request.data);

  // ✅ Check authentication
  if (!request.auth) {
    console.log('❌ [removeCollaborator] No authentication found');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const currentUserId = request.auth.uid;
  console.log('✅ [removeCollaborator] User authenticated:', currentUserId);

  const { dictionaryId, userId } = request.data;

  // 🛠 Validate input
  if (!dictionaryId || !userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  // ⛔ Prevent self-removal
  if (userId === currentUserId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cannot remove yourself as a collaborator'
    );
  }

  try {
    const db = admin.firestore();
    const dictionaryRef = db.collection('dictionaries').doc(dictionaryId);
    const dictionaryDoc = await dictionaryRef.get();

    // 🔐 Check dictionary existence
    if (!dictionaryDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Dictionary not found');
    }

    const dictionaryData = dictionaryDoc.data();

    // 🔐 Check owner permission
    if (dictionaryData.owner !== currentUserId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only the owner can remove collaborators'
      );
    }

    // Check if user is a collaborator
    if (!dictionaryData.collaborators || !dictionaryData.collaborators[userId]) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'User is not a collaborator in this dictionary'
      );
    }

    // ✅ Remove collaborator with transaction
    await db.runTransaction(async (transaction) => {
      const updatedDoc = await transaction.get(dictionaryRef);
      if (!updatedDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Dictionary not found');
      }
      transaction.update(dictionaryRef, {
        [`collaborators.${userId}`]: admin.firestore.FieldValue.delete(),
      });
    });

    console.log(
      `✅ [removeCollaborator] User ${currentUserId} removed ${userId} from dictionary ${dictionaryId}`
    );

    return { success: true, message: 'Collaborator removed successfully' };
  } catch (error) {
    console.error('❌ [removeCollaborator] Error:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to remove collaborator');
  }
});

// Test function to verify authentication
exports.testAuth = functions.https.onCall({ region }, async (request) => {
  console.log('🔍 [testAuth] Function called');
  console.log('🔍 [testAuth] Auth:', request.auth);
  console.log('🔍 [testAuth] Data:', request.data);
  
  if (!request.auth) {
    console.log('❌ [testAuth] No authentication found');
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const currentUserId = request.auth.uid;
  const currentUserEmail = request.auth.token?.email || 'No email';
  
  console.log('✅ [testAuth] User authenticated:', currentUserId);
  console.log('✅ [testAuth] User email:', currentUserEmail);
  
  return {
    success: true,
    message: 'Authentication successful',
    uid: currentUserId,
    email: currentUserEmail,
    timestamp: new Date().toISOString()
  };
});