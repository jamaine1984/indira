const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'indira-love.firebasestorage.app'
});

const db = admin.firestore();
const auth = admin.auth();

// Test user data
const testUsers = [
  {
    email: 'sarah.anderson@test.com',
    password: 'Test123!@#',
    profile: {
      displayName: 'Sarah Anderson',
      age: 28,
      gender: 'female',
      bio: 'Yoga instructor and travel enthusiast. Love hiking, photography, and trying new cuisines.',
      interests: ['Yoga', 'Travel', 'Photography', 'Hiking', 'Cooking'],
      lookingFor: 'male',
      location: {
        city: 'Los Angeles',
        state: 'California',
        country: 'USA',
        latitude: 34.0522,
        longitude: -118.2437
      },
      education: 'Bachelor\'s Degree',
      occupation: 'Yoga Instructor',
      height: 165,
      religion: 'Spiritual',
      drinking: 'Socially',
      smoking: 'No',
      verified: true,
      profileComplete: true,
      photoURL: 'https://via.placeholder.com/400x400/FF69B4/FFFFFF?text=Sarah',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  },
  {
    email: 'michael.chen@test.com',
    password: 'Test123!@#',
    profile: {
      displayName: 'Michael Chen',
      age: 32,
      gender: 'male',
      bio: 'Software engineer by day, chef by night. Looking for someone who enjoys good food and deep conversations.',
      interests: ['Cooking', 'Technology', 'Reading', 'Tennis', 'Wine'],
      lookingFor: 'female',
      location: {
        city: 'San Francisco',
        state: 'California',
        country: 'USA',
        latitude: 37.7749,
        longitude: -122.4194
      },
      education: 'Master\'s Degree',
      occupation: 'Software Engineer',
      height: 178,
      religion: 'Agnostic',
      drinking: 'Socially',
      smoking: 'No',
      verified: true,
      profileComplete: true,
      photoURL: 'https://via.placeholder.com/400x400/4169E1/FFFFFF?text=Michael',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  },
  {
    email: 'emma.rodriguez@test.com',
    password: 'Test123!@#',
    profile: {
      displayName: 'Emma Rodriguez',
      age: 26,
      gender: 'female',
      bio: 'Artist and coffee lover. I paint, run marathons, and believe in kindness above all.',
      interests: ['Art', 'Running', 'Coffee', 'Music', 'Volunteering'],
      lookingFor: 'male',
      location: {
        city: 'New York',
        state: 'New York',
        country: 'USA',
        latitude: 40.7128,
        longitude: -74.0060
      },
      education: 'Bachelor\'s Degree',
      occupation: 'Graphic Designer',
      height: 168,
      religion: 'Catholic',
      drinking: 'Rarely',
      smoking: 'No',
      verified: true,
      profileComplete: true,
      photoURL: 'https://via.placeholder.com/400x400/32CD32/FFFFFF?text=Emma',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  }
];

async function createTestUsers() {
  console.log('🚀 Creating test users in Firebase...\n');

  for (const userData of testUsers) {
    try {
      // Create authentication user
      console.log(`Creating auth user: ${userData.email}...`);
      const userRecord = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.profile.displayName,
        photoURL: userData.profile.photoURL,
        emailVerified: true
      });

      console.log(`✅ Auth user created: ${userRecord.uid}`);

      // Create Firestore profile document
      console.log(`Creating Firestore profile for: ${userData.profile.displayName}...`);
      await db.collection('users').doc(userRecord.uid).set({
        ...userData.profile,
        uid: userRecord.uid,
        email: userData.email,
        emailVerified: true
      });

      console.log(`✅ Profile created in Firestore\n`);

    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`⚠️  User ${userData.email} already exists, skipping...\n`);
      } else {
        console.error(`❌ Error creating user ${userData.email}:`, error.message, '\n');
      }
    }
  }

  console.log('\n✅ All test users created successfully!');
  console.log('\nTest User Credentials:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  testUsers.forEach(user => {
    console.log(`Email: ${user.email}`);
    console.log(`Password: ${user.password}`);
    console.log(`Name: ${user.profile.displayName}\n`);
  });

  process.exit(0);
}

createTestUsers();
