// firebase deploy --only functions
// npm run lint -- --fix

const {setGlobalOptions} = require("firebase-functions");
const {onCall} = require("firebase-functions/v2/https");
const {beforeUserCreated} = require("firebase-functions/v2/identity");

setGlobalOptions({maxInstances: 5});

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();


// === ADMIN FUNCTIONS ===

// Grant admin privileges to a user by email
exports.grantAdminRole = onCall(async (request) => {
  // Only existing admins can grant admin role
  if (!request.auth || !request.auth.token.admin) {
    console.log("Permission denied - no auth or no admin claim");
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can grant admin role.",
    );
  }

  const {email} = request.data;

  if (!email) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Email is required.",
    );
  }

  try {
    // Find user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // Set custom claims using the UID
    await admin.auth().setCustomUserClaims(userRecord.uid, {admin: true});

    return {
      message: `Admin role granted to ${email} (UID: ${userRecord.uid})`,
      success: true,
      uid: userRecord.uid,
      email: email,
    };
  } catch (error) {
    console.log("Error in grantAdminRole:", error);

    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError(
          "not-found",
          `User with email ${email} not found in Firebase Auth.`,
      );
    }

    throw new functions.https.HttpsError(
        "internal",
        "Failed to grant admin role",
        error,
    );
  }
});

// Bootstrap function to grant first admin (run once manually)
exports.grantFirstAdmin = functions.https.onRequest(async (req, res) => {
  const {email, secret} = req.body;

  // Use a secret key for security
  if (secret !== "cipher-admin-secret-2025") {
    return res.status(403).json({error: "Invalid secret"});
  }

  try {
    // Find user by email
    const user = await admin.auth().getUserByEmail(email);

    // Grant admin privileges
    await admin.auth().setCustomUserClaims(user.uid, {admin: true});

    res.json({
      message: `First admin granted to ${email}`,
      uid: user.uid,
      success: true,
    });
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

// Remove admin role
exports.revokeAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can revoke admin role.",
    );
  }

  const {uid} = data;

  try {
    await admin.auth().setCustomUserClaims(uid, {admin: false});

    return {
      message: `Admin role revoked from user ${uid}`,
      success: true,
    };
  } catch (error) {
    throw new functions.https.HttpsError(
        "internal",
        "Failed to revoke admin role",
        error,
    );
  }
});


// === USER INITIALIZATION ===

// Create user document in Firestore when a new user signs up
exports.createUserDocument = beforeUserCreated(async (event) => {
  const {uid, email, displayName} = event.data;

  try {
    await admin.firestore().collection("users").doc(uid).set({
      uid: uid,
      email: email || "",
      userName: displayName || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User document created for ${uid} (${email})`);
    return {success: true};
  } catch (error) {
    console.error("Error creating user document:", error);
    // Note: beforeUserCreated cannot throw HttpsError
    // Log the error and continue
    return {success: false, error: error.message};
  }
});


// === PLAYLIST SHARING ===

// Callable function to join a schedule using a share code
exports.joinScheduleWithCode = onCall(async (request) => {
  // Authentication required
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to join a schedule.",
    );
  }

  const {shareCode} = request.data;
  const userId = request.auth.uid;

  if (!shareCode || typeof shareCode !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid share code is required.",
    );
  }

  try {
    const db = admin.firestore();

    // Find the share code document
    const scheduleSnap = await db.collection("schedules")
        .where("shareCode", "==", shareCode)
        .limit(1)
        .get();

    if (scheduleSnap.empty) {
      throw new functions.https.HttpsError(
          "not-found",
          "Invalid or expired share code.",
      );
    }

    const scheduleDoc = scheduleSnap.docs[0];
    const scheduleId = scheduleDoc.id;

    const scheduleData = scheduleDoc.data();

    // Check if user is already a collaborator
    const currentCollaborators = scheduleData.collaborators || [];
    if (currentCollaborators.includes(userId)) {
      throw new functions.https.HttpsError(
          "already-exists",
          "You are already a collaborator on this schedule.",
      );
    }

    // Add user as collaborator to the schedule
    await db.collection("schedules").doc(scheduleId).update({
      collaborators: admin.firestore.FieldValue.arrayUnion(userId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User ${userId} joined schedule ${scheduleId} via share code`);

    return {
      success: true,
      message: "Successfully joined schedule",
      scheduleId: scheduleId,
    };
  } catch (error) {
    console.error("Error in joinScheduleWithCode:", error);

    // Re-throw if it's already an HttpsError
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
        "internal",
        "Failed to join schedule",
        error,
    );
  }
});
