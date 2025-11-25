const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCollections() {
  const collections = ['users', 'likes', 'matches', 'chats', 'swipes', 'blocked_users',
                       'gifts', 'user_gifts', 'social_posts', 'notifications',
                       'speed_dating_rooms', 'speed_dating_sessions'];

  console.log('\n========================================');
  console.log('FIRESTORE VERIFICATION REPORT');
  console.log('========================================\n');

  let totalDocs = 0;

  for (const collectionName of collections) {
    try {
      const snapshot = await db.collection(collectionName).limit(5).get();
      const count = snapshot.size;
      totalDocs += count;

      if (count > 0) {
        console.log(`❌ ${collectionName}: ${count} documents found`);
        snapshot.forEach(doc => {
          console.log(`   - ${doc.id}`);
        });
      } else {
        console.log(`✅ ${collectionName}: EMPTY`);
      }
    } catch (error) {
      console.log(`⚠️  ${collectionName}: Error checking - ${error.message}`);
    }
  }

  console.log('\n========================================');
  if (totalDocs === 0) {
    console.log('✅ VERIFIED: Firestore is completely empty!');
  } else {
    console.log(`❌ WARNING: Found ${totalDocs} documents still in Firestore`);
  }
  console.log('========================================\n');

  process.exit(0);
}

checkCollections();
