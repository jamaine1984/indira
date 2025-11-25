# Creating Test Users for Indira Love

## Step 1: Download Service Account Key

1. Go to Firebase Console: https://console.firebase.google.com/project/indira-love/settings/serviceaccounts/adminsdk
2. Click **"Generate new private key"**
3. Save the downloaded JSON file as `serviceAccountKey.json` in `C:\Users\koike\Downloads\indira\`

## Step 2: Install Dependencies

```bash
cd C:\Users\koike\Downloads\indira
npm install firebase-admin
```

## Step 3: Run the Script

```bash
node create_test_users.js
```

## Test Users That Will Be Created:

### User 1: Sarah Anderson
- **Email:** sarah.anderson@test.com
- **Password:** Test123!@#
- Age: 28, Female
- Location: Los Angeles, CA
- Interests: Yoga, Travel, Photography, Hiking, Cooking

### User 2: Michael Chen
- **Email:** michael.chen@test.com
- **Password:** Test123!@#
- Age: 32, Male
- Location: San Francisco, CA
- Interests: Cooking, Technology, Reading, Tennis, Wine

### User 3: Emma Rodriguez
- **Email:** emma.rodriguez@test.com
- **Password:** Test123!@#
- Age: 26, Female
- Location: New York, NY
- Interests: Art, Running, Coffee, Music, Volunteering

## After Creation:

1. Open your Indira Love app
2. Sign in as any user
3. Go to Discover page
4. You should see the other 2 test users!

## Troubleshooting:

- If you get "email-already-exists", the users are already created
- If you get permission errors, make sure the service account key is correct
- Check Firebase Console → Authentication to verify users were created
