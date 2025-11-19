const functions = require('firebase-functions');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

/**
 * SERVER-SIDE MATCHING OPTIMIZATION FOR INDIRA LOVE
 *
 * This function pre-calculates and caches compatibility scores
 * to avoid expensive client-side calculations at scale.
 *
 * Features:
 * - Calculates compatibility scores server-side (5-factor algorithm)
 * - Stores results in 'match_scores' collection with 24h TTL
 * - Supports batch processing for efficiency
 * - Implements pagination for large user bases
 */

// Calculate compatibility score between two users
exports.calculateMatchScore = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, targetUserId } = data;

  if (!userId || !targetUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'User IDs are required');
  }

  try {
    const db = admin.firestore();

    // Get both user documents
    const [userDoc, targetDoc] = await Promise.all([
      db.collection('users').doc(userId).get(),
      db.collection('users').doc(targetUserId).get()
    ]);

    if (!userDoc.exists || !targetDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User(s) not found');
    }

    const user = userDoc.data();
    const target = targetDoc.data();

    // Calculate 5-factor compatibility score (from Indira's algorithm)
    const score = await calculate5FactorScore(user, target);

    // Store in cache with 24h TTL
    await db.collection('match_scores').doc(`${userId}_${targetUserId}`).set({
      userId,
      targetUserId,
      score,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 24 * 60 * 60 * 1000)
      )
    });

    console.log(`✅ Calculated match score: ${userId} → ${targetUserId} = ${score}`);
    return { score, userId, targetUserId };
  } catch (error) {
    console.error('❌ Error calculating match score:', error);
    throw new functions.https.HttpsError('internal', `Failed to calculate match score: ${error.message}`);
  }
});

// Batch calculate match scores for discovery
exports.batchCalculateMatches = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, limit = 50 } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
  }

  try {
    const db = admin.firestore();

    // Get current user
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const user = userDoc.data();

    // Get users that haven't been interacted with
    const [likesSnapshot, swipesSnapshot] = await Promise.all([
      db.collection('likes').where('likerId', '==', userId).get(),
      db.collection('swipes').where('userId', '==', userId).get()
    ]);

    const interactedIds = new Set([userId]);
    likesSnapshot.docs.forEach(doc => interactedIds.add(doc.data().likedUserId));
    swipesSnapshot.docs.forEach(doc => interactedIds.add(doc.data().targetUserId));

    // Get potential matches (excluding already interacted)
    let query = db.collection('users')
      .where('gender', '==', user.lookingFor || user.gender)
      .limit(Math.min(limit * 2, 100));

    const potentialMatches = await query.get();
    const scoredMatches = [];

    // Process in batches of 10 to avoid timeouts
    const batchSize = 10;
    for (let i = 0; i < potentialMatches.docs.length; i += batchSize) {
      const batch = potentialMatches.docs.slice(i, i + batchSize);

      const results = await Promise.all(
        batch
          .filter(doc => !interactedIds.has(doc.id))
          .map(async (doc) => {
            const target = doc.data();
            const score = await calculate5FactorScore(user, target);

            // Store in cache
            await db.collection('match_scores').doc(`${userId}_${doc.id}`).set({
              userId,
              targetUserId: doc.id,
              score,
              calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
              expiresAt: admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + 24 * 60 * 60 * 1000)
              )
            });

            return {
              userId: doc.id,
              score,
              ...target
            };
          })
      );

      scoredMatches.push(...results);

      if (scoredMatches.length >= limit) break;
    }

    // Sort by score descending and limit
    const topMatches = scoredMatches
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    console.log(`✅ Batch calculated ${topMatches.length} matches for user ${userId}`);
    return { topMatches, count: topMatches.length };
  } catch (error) {
    console.error('❌ Error batch calculating matches:', error);
    throw new functions.https.HttpsError('internal', `Failed to batch calculate matches: ${error.message}`);
  }
});

// Scheduled function to recalculate match scores (runs daily)
exports.dailyMatchScoreUpdate = onSchedule('every 24 hours', async (event) => {
    console.log('🔄 Starting daily match score update');

    const db = admin.firestore();

    try {
      // Get all users
      const usersSnapshot = await db.collection('users').limit(1000).get();
      console.log(`Processing ${usersSnapshot.size} users`);

      let totalScoresCalculated = 0;

      // Process in batches
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const user = userDoc.data();

        // Get top 50 potential matches
        let query = db.collection('users')
          .where(admin.firestore.FieldPath.documentId(), '!=', userId)
          .limit(50);

        const potentialMatches = await query.get();

        // Calculate scores for each
        for (const targetDoc of potentialMatches.docs) {
          const target = targetDoc.data();
          const score = await calculate5FactorScore(user, target);

          await db.collection('match_scores').doc(`${userId}_${targetDoc.id}`).set({
            userId,
            targetUserId: targetDoc.id,
            score,
            calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 24 * 60 * 60 * 1000)
            )
          });

          totalScoresCalculated++;
        }

        // Limit processing to avoid timeouts
        if (totalScoresCalculated >= 10000) break;
      }

      console.log(`✅ Daily update complete: ${totalScoresCalculated} scores calculated`);
      return null;
    } catch (error) {
      console.error('❌ Error in daily match score update:', error);
      return null;
    }
  });

// Clean up expired match scores
exports.cleanupExpiredScores = onSchedule('every 6 hours', async (event) => {
    console.log('🧹 Cleaning up expired match scores');

    const db = admin.firestore();

    try {
      const now = admin.firestore.Timestamp.now();
      const expiredScores = await db.collection('match_scores')
        .where('expiresAt', '<=', now)
        .limit(500)
        .get();

      if (expiredScores.empty) {
        console.log('No expired scores to clean up');
        return null;
      }

      const batch = db.batch();
      expiredScores.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      console.log(`✅ Cleaned up ${expiredScores.size} expired scores`);
      return null;
    } catch (error) {
      console.error('❌ Error cleaning up expired scores:', error);
      return null;
    }
  });

// Helper: Calculate 5-factor compatibility score (Indira's algorithm)
async function calculate5FactorScore(user1, user2) {
  const weights = {
    interests: 0.30,    // 30 points
    distance: 0.25,     // 25 points
    age: 0.15,          // 15 points
    activity: 0.15,     // 15 points
    completeness: 0.10, // 10 points
  };

  let totalScore = 0;

  // 1. Shared interests (30 points)
  const interests1 = new Set(user1.interests || []);
  const interests2 = new Set(user2.interests || []);
  if (interests1.size > 0 && interests2.size > 0) {
    const commonInterests = [...interests1].filter(i => interests2.has(i));
    const interestScore = (commonInterests.length / interests1.size) * 30;
    totalScore += interestScore;
  }

  // 2. Distance proximity (25 points)
  if (user1.location && user2.location) {
    try {
      const distance = calculateDistance(
        user1.location._latitude || user1.location.latitude,
        user1.location._longitude || user1.location.longitude,
        user2.location._latitude || user2.location.latitude,
        user2.location._longitude || user2.location.longitude
      );

      let distanceScore = 0;
      if (distance < 5) distanceScore = 25;
      else if (distance < 25) distanceScore = 20;
      else if (distance < 50) distanceScore = 15;
      else if (distance < 100) distanceScore = 10;
      else distanceScore = 5;

      totalScore += distanceScore;
    } catch (e) {
      console.log('Distance calculation skipped:', e.message);
    }
  }

  // 3. Age compatibility (15 points)
  if (user1.age && user2.age) {
    const ageDiff = Math.abs(user1.age - user2.age);
    let ageScore = 0;
    if (ageDiff <= 2) ageScore = 15;
    else if (ageDiff <= 5) ageScore = 12;
    else if (ageDiff <= 10) ageScore = 8;
    else ageScore = 4;

    totalScore += ageScore;
  }

  // 4. Activity level (15 points)
  if (user2.lastSeen) {
    const lastSeen = user2.lastSeen.toDate ? user2.lastSeen.toDate() : new Date(user2.lastSeen);
    const hoursSince = (Date.now() - lastSeen.getTime()) / (1000 * 60 * 60);

    let activityScore = 0;
    if (hoursSince < 1) activityScore = 15;
    else if (hoursSince < 24) activityScore = 12;
    else if (hoursSince < 72) activityScore = 8;
    else activityScore = 4;

    totalScore += activityScore;
  }

  // 5. Profile completeness (10 points)
  let completenessScore = 0;
  if (user2.photos && user2.photos.length > 0) completenessScore += 4;
  if (user2.bio && user2.bio.length > 0) completenessScore += 3;
  if (user2.interests && user2.interests.length > 0) completenessScore += 3;

  totalScore += completenessScore;

  return Math.round(totalScore * 100) / 100; // Round to 2 decimals
}

// Helper: Calculate distance using Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}
