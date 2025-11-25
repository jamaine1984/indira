const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://global-speed-dating.firebaseio.com'
});

const db = admin.firestore();

async function checkUsers() {
  try {
    console.log('Querying users collection...');
    const usersSnapshot = await db.collection('users').get();

    console.log(`\nTotal users found: ${usersSnapshot.size}`);
    console.log('\nUser IDs and names:');

    usersSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${doc.id} (${data.displayName || 'No name'})`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Error querying users:', error);
    process.exit(1);
  }
}

checkUsers();
