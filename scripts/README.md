# Indira Love - Scripts Documentation

## 📁 Available Scripts

### 1. populate_profanity_filter.js

**Purpose**: Populates Firestore with comprehensive profanity and content moderation filters.

**What it does:**
- Adds 150+ inappropriate words and phrases to block
- Configures spam pattern detection (phone numbers, emails, URLs)
- Sets up severity levels for graduated moderation responses
- Creates moderation logging configuration
- Enables auto-blocking after threshold violations

**Categories Covered:**
- ✅ Profanity and vulgar language
- ✅ Sexual and explicit content
- ✅ Hate speech (racial, LGBTQ+, religious, ethnic)
- ✅ Harassment and abuse terms
- ✅ Scam and spam keywords
- ✅ Drug-related terms
- ✅ Violence and threats
- ✅ Minor protection keywords

---

## 🚀 How to Run

### Prerequisites

1. **Firebase Admin SDK credentials**

   Create a service account in Firebase console:
   ```
   Firebase Console → Project Settings → Service Accounts
   → Generate new private key
   ```

   Save the JSON file as: `~/indira/functions/serviceAccountKey.json`

2. **Install dependencies** (if not already installed)

   ```bash
   cd ~/indira/functions
   npm install
   ```

---

### Option 1: Run Standalone Script

**Step 1: Create a runner script**

Create `scripts/run_profanity_filter.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('../functions/serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com'  // Replace with your Firebase URL
});

// Run the population script
require('./populate_profanity_filter.js');
```

**Step 2: Run the script**

```bash
cd ~/indira
node scripts/run_profanity_filter.js
```

---

### Option 2: Run via Firebase Functions

**Step 1: Add to Cloud Functions**

Add to `functions/index.js`:

```javascript
const populateFilter = require('../scripts/populate_profanity_filter.js');

// One-time setup function (call manually via Firebase console)
exports.setupProfanityFilter = functions.https.onRequest(async (req, res) => {
  try {
    await populateFilter();
    res.status(200).send('✅ Profanity filter populated successfully!');
  } catch (error) {
    res.status(500).send(`❌ Error: ${error.message}`);
  }
});
```

**Step 2: Deploy and trigger**

```bash
cd ~/indira/functions
firebase deploy --only functions:setupProfanityFilter

# Trigger via browser or curl
curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/setupProfanityFilter
```

---

### Option 3: Direct Firestore Population (Quickest)

**Use the Firebase console to manually add the document:**

1. Go to: https://console.firebase.google.com
2. Navigate to **Firestore Database**
3. Create collection: `app_config`
4. Create document: `profanity_filter`
5. Copy the content from the script and paste as fields

**OR use Firebase CLI:**

```bash
# Create a simplified JSON version
cat > /tmp/profanity_filter.json << 'EOF'
{
  "enabled": true,
  "words": ["fuck", "shit", "bitch", "..." ],
  "lastUpdated": { "_seconds": 1234567890 }
}
EOF

# Import to Firestore
firebase firestore:import /tmp/profanity_filter.json
```

---

## 🔍 Verification

After running the script, verify it worked:

**Check Firestore Console:**
```
Firestore Database → app_config → profanity_filter

Should see:
- enabled: true
- words: [150+ entries]
- spamPatterns: [regex patterns]
- contextRules: {severity levels}
- totalWords: 150+
```

**Test in your app:**

```dart
import 'package:indira_love/core/services/validation_service.dart';

// Test profanity detection
final result = await ValidationService().checkProfanity('test message with badword');

if (!result.isValid) {
  print('🚫 Content blocked: ${result.message}');
}
```

---

## 📊 Moderation Configuration

The script configures the following moderation rules:

| Setting | Value | Description |
|---------|-------|-------------|
| **Alert Threshold** | 5 violations | User flagged for review |
| **Auto-Block Threshold** | 10 violations | Automatic account suspension |
| **Log Retention** | 90 days | How long to keep moderation logs |
| **Severity Levels** | 4 tiers | Critical, High, Medium, Low |

### Severity Actions

- **Critical** (rape, pedophile, KYS): Instant ban + police report
- **High** (slurs, hate speech): Account review + warning
- **Medium** (profanity): Message blocked + counter increment
- **Low** (mild profanity): Warning only

---

## 🛠️ Customization

### Adding More Words

Edit `populate_profanity_filter.js` and add to the `profanityWords` array:

```javascript
const profanityWords = [
  // ... existing words
  'newbadword',
  'anotherbadword',
];
```

Re-run the script to update Firestore.

### Adjusting Severity

Modify the `contextRules.severity` object:

```javascript
severity: {
  critical: ['word1', 'word2'],  // Instant ban
  high: ['word3'],                // Warning + review
  medium: ['word4'],              // Block message
  low: ['word5'],                 // Log only
}
```

### Allowlisting Legitimate Words

Add to `contextRules.allowedPhrases`:

```javascript
allowedPhrases: [
  'basketball',   // Contains 'ball'
  'classic',      // Contains 'ass'
  'therapist',    // Contains 'rapist'
]
```

---

## 🔧 Troubleshooting

### Error: "Firebase Admin not initialized"
**Solution**: Make sure you have a valid service account key and initialized Firebase Admin.

### Error: "Permission denied"
**Solution**: Ensure Firestore rules allow writes to `app_config` collection from Cloud Functions or admin SDK.

### Error: "Module not found"
**Solution**: Run `npm install` in the `functions/` directory first.

### Words not being filtered in app
**Solution**:
1. Verify filter exists in Firestore: `app_config/profanity_filter`
2. Check `ValidationService` is called before saving messages/posts
3. Ensure `enabled: true` in the filter document

---

## 🎯 Next Steps

After populating the filter:

1. **Integrate in app code** - Ensure all user input is validated:
   - Messages (conversation_screen.dart)
   - Profile bio (edit_profile_screen.dart)
   - Lovers Anonymous posts (social_screen.dart)
   - Display names (registration)

2. **Monitor moderation logs** - Check `moderation_logs` collection regularly:
   ```javascript
   // View recent violations
   db.collection('moderation_logs')
     .orderBy('timestamp', 'desc')
     .limit(100)
     .get()
   ```

3. **Tune thresholds** - Adjust based on real-world usage:
   - Too many false positives? Add to allowedPhrases
   - Missing content? Add to profanityWords
   - Too strict? Lower severity levels

4. **Add ML moderation** (future enhancement):
   - Integrate Perspective API for toxicity scoring
   - Use Firebase ML Kit for image moderation
   - Implement user reporting system

---

## 📝 License & Legal

This profanity filter is designed for content moderation in a dating app context. The word list is based on common community standards and legal requirements for online platforms.

**Important Legal Notes:**
- Filter complies with GDPR Article 5 (data minimization)
- Logs are retained for 90 days (configurable)
- Users can appeal moderation decisions
- Transparency report can be generated from logs

**Disclaimer**: No filter is 100% perfect. Always allow manual review and user appeals.

---

## 📞 Support

If you encounter issues:
1. Check Firestore console for the filter document
2. Review Firebase Functions logs for errors
3. Test with ValidationService in your Flutter app
4. Adjust severity/thresholds as needed

**Last Updated**: Script created for Indira Love production deployment
