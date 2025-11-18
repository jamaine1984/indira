# Production Readiness Migration Guide for Indira Love

This document outlines all the changes made to make the Indira Love dating app production-ready and provides instructions for completing the migration.

## ✅ Completed Services

### 1. Logger Service (`lib/core/services/logger_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - Replaces all print() statements
  - Integrates with Firebase Crashlytics
  - Multiple log levels (debug, info, warning, error, fatal)
  - Security event logging
  - User action logging
  - Network request logging

**Usage**:
```dart
import 'package:indira_love/core/services/logger_service.dart';

// Replace print() with:
logger.debug('Debug message');
logger.info('Info message');
logger.warning('Warning message', error: e);
logger.error('Error message', error: e, stackTrace: stackTrace);
logger.logSecurityEvent('Security event', userId: userId);
```

### 2. Validation Service (`lib/core/services/validation_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - Input sanitization (XSS protection)
  - Profanity filtering
  - Scam detection
  - Email/password/phone validation
  - Bio/message content validation
  - URL and contact info detection

**Usage**:
```dart
import 'package:indira_love/core/services/validation_service.dart';

// Validate user inputs
final result = validation.validateDisplayName(name);
if (!result.isValid) {
  showError(result.message);
}

// Sanitize text
final cleanText = validation.sanitizeText(userInput);
```

### 3. Encryption Service (`lib/core/services/encryption_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - AES-256 message encryption
  - Server-managed encryption keys
  - Message encryption/decryption
  - File encryption support
  - Secure token generation

**Usage**:
```dart
import 'package:indira_love/core/services/encryption_service.dart';

// Encrypt messages before saving
final encrypted = encryption.encryptMessage(plainText);

// Decrypt messages for display
final decrypted = encryption.decryptMessage(encryptedText);
```

**⚠️ IMPORTANT**: Set up encryption keys in Firestore:
```
Collection: app_config
Document: encryption
Fields:
  - master_key: (generate via encryption.initialize())
  - master_iv: (auto-generated)
```

### 4. Data Export Service (`lib/core/services/data_export_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - GDPR Article 20 compliance (Right to Data Portability)
  - Export all user data to JSON
  - Generate download links
  - Privacy reports
  - Export history tracking

**Usage**:
```dart
import 'package:indira_love/core/services/data_export_service.dart';

// Export user data
final data = await dataExport.exportUserData(userId);

// Generate download URL
final url = await dataExport.exportUserDataToStorage(userId);
```

### 5. Account Deletion Service (`lib/core/services/account_deletion_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - GDPR Article 17 compliance (Right to Erasure)
  - 30-day grace period for deletions
  - Complete data removal from Firestore
  - Storage file deletion
  - Data anonymization for legal retention

**Usage**:
```dart
import 'package:indira_love/core/services/account_deletion_service.dart';

// Request deletion (30-day grace period)
await accountDeletion.requestAccountDeletion(userId);

// Cancel deletion request
await accountDeletion.cancelAccountDeletion(userId);

// Immediate deletion (with password confirmation)
await accountDeletion.deleteUserAccount(userId, password);
```

### 6. Analytics Service (`lib/core/services/analytics_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - Firebase Analytics integration
  - Custom event tracking
  - User property management
  - Conversion tracking
  - Admin dashboard analytics

**Usage**:
```dart
import 'package:indira_love/core/services/analytics_service.dart';

// Track events
await analytics.logSignUp('email');
await analytics.logMatch(matchedUserId);
await analytics.logMessageSent(receiverId, 'text');
```

### 7. Rate Limiter Service (`lib/core/services/rate_limiter_service.dart`)
- **Status**: ✅ Created
- **Features**:
  - Prevents spam and abuse
  - Configurable limits per action
  - Minute/hour/day limits
  - Premium tier support
  - Temporary ban system

**Usage**:
```dart
import 'package:indira_love/core/services/rate_limiter_service.dart';

// Check if action is allowed
final result = await rateLimiter.checkMessageLimit(userId);
if (!result.allowed) {
  showError(result.reason);
  return;
}

// Perform action...
```

**Rate Limits**:
- Swipes: 100/hour, 500/day
- Likes: 50/hour, 200/day
- Superlikes: 5/day
- Messages: 10/minute, 100/hour, 500/day
- Reports: 10/day
- Profile updates: 5/hour
- Photo uploads: 20/day

### 8. Improved IAP Service (`lib/core/services/iap_service_improved.dart`)
- **Status**: ✅ Created
- **Features**:
  - Server-side receipt verification
  - Fraud detection
  - Purchase logging and auditing
  - Fallback verification
  - Transaction security

**Usage**:
```dart
import 'package:indira_love/core/services/iap_service_improved.dart';

// Initialize
await iapService.initialize();

// Purchase
final success = await iapService.purchase(productId);
```

**⚠️ REQUIRED**: Deploy Cloud Function for receipt verification (see below)

### 9. Legal Documents
- **Status**: ✅ Created
- **Files**:
  - `lib/features/legal/terms_of_service.dart`
  - `lib/features/legal/privacy_policy.dart`
  - `lib/features/legal/community_guidelines.dart`

**Usage**: Add navigation links in settings/profile screens

## 📋 TODO: Manual Migration Tasks

### Task 1: Replace All print() Statements

**Files with print() statements** (21 files total):
1. `lib/main.dart` - 4 statements
2. `lib/core/services/iap_service.dart` - 19 statements
3. `lib/core/widgets/watch_ads_dialog.dart` - 6 statements
4. `lib/core/services/database_service.dart` - 7 statements
5. `lib/core/services/notification_service.dart` - 1 statement
6. `lib/core/services/scam_detection_service.dart` - 2 statements
7. `lib/core/services/matching_algorithm_service.dart` - 3 statements
8. `lib/core/services/matches_service.dart` - 1 statement
9. `lib/core/services/push_notification_service.dart` - 6 statements
10. `lib/core/services/location_service.dart` - 2 statements
11. `lib/features/verification/services/verification_service.dart` - 2 statements
12. `lib/features/messaging/services/voice_message_service.dart` - 8 statements
13. `lib/features/likes/services/likes_service.dart` - 3 statements
14. `lib/features/likes/services/boost_service.dart` - 11 statements
15. `lib/features/discover/presentation/widgets/swipe_card.dart` - 12 statements
16. `lib/features/discover/presentation/providers/discover_provider.dart` - 30+ statements
17. `lib/features/discover/presentation/screens/discover_screen.dart` - 1 statement
18. `lib/features/social/presentation/screens/social_screen.dart` - statements
19. `lib/features/messaging/presentation/screens/conversation_screen.dart` - statements
20. `lib/features/likes/presentation/widgets/boost_dialog.dart` - statements
21. `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` - 2 statements

**Search and replace pattern**:
```bash
# Find all print statements
grep -rn "print(" lib/

# Replace pattern:
Old: print('message');
New: logger.debug('message');

Old: print('Error: $e');
New: logger.error('Error', error: e);
```

**Manual replacement needed for each file**:
1. Add import: `import 'package:indira_love/core/services/logger_service.dart';`
2. Replace `print()` with appropriate logger method:
   - `print('debug info')` → `logger.debug('debug info')`
   - `print('warning')` → `logger.warning('warning')`
   - `print('Error: $e')` → `logger.error('Error', error: e)`

### Task 2: Initialize Services in main.dart

**Update `lib/main.dart`**:
```dart
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/validation_service.dart';
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize logger (first - so other services can use it)
  await logger.initialize();

  // Initialize other services
  await validation.initialize();
  await encryption.initialize();
  await analytics.initialize();
  await rateLimiter.initialize();

  // ... rest of initialization

  runApp(const MyApp());
}
```

### Task 3: Update pubspec.yaml Dependencies

**Already added**:
- ✅ `firebase_crashlytics: ^3.4.9`
- ✅ `encrypt: ^5.0.3`
- ✅ `crypto: ^3.0.3`

**Need to add**:
```yaml
dependencies:
  # Add http for server verification
  http: ^1.1.0
```

**Run**:
```bash
flutter pub get
```

### Task 4: Set Up Firebase Crashlytics (Android)

**android/app/build.gradle**:
```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'
    id 'com.google.firebase.crashlytics' // Add this
}

dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-crashlytics'
}
```

**android/build.gradle**:
```gradle
buildscript {
    dependencies {
        // ... existing
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}
```

### Task 5: Deploy Cloud Functions

**Install dependencies**:
```bash
cd functions
npm install firebase-functions firebase-admin googleapis axios
```

**functions/package.json**:
```json
{
  "name": "functions",
  "scripts": {
    "deploy": "firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-functions": "^4.5.0",
    "firebase-admin": "^11.11.1",
    "googleapis": "^128.0.0",
    "axios": "^1.6.2"
  }
}
```

**Configure API keys**:
```bash
# Apple App Store shared secret
firebase functions:config:set apple.shared_secret="YOUR_SHARED_SECRET"

# Google Play service account (upload service-account.json first)
firebase functions:config:set google.service_account="$(cat service-account.json)"
```

**Deploy**:
```bash
firebase deploy --only functions
```

### Task 6: Set Up Firestore Collections

**Required collections** (create indexes as needed):

1. **app_config**:
   - `encryption` doc: encryption keys
   - `profanity_filter` doc: profanity word list

2. **rate_limits**: User action tracking
3. **receipt_verifications**: IAP verification logs
4. **security_events**: Security incident logs
5. **data_exports**: User data export records
6. **account_deletions**: Deletion audit trail
7. **fraudulent_purchases**: Failed verification attempts

**Example profanity filter setup**:
```javascript
// In Firestore console
db.collection('app_config').doc('profanity_filter').set({
  words: ['badword1', 'badword2', 'scam', 'sugar daddy', ...]
});
```

### Task 7: Integrate Services in Existing Features

**Message sending** (add encryption):
```dart
// In conversation_screen.dart
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/validation_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';

Future<void> sendMessage(String text) async {
  // Validate message
  final validationResult = validation.validateMessage(text);
  if (!validationResult.isValid) {
    showError(validationResult.message);
    return;
  }

  // Check rate limit
  final rateLimitResult = await rateLimiter.checkMessageLimit(userId);
  if (!rateLimitResult.allowed) {
    showError(rateLimitResult.reason);
    return;
  }

  // Encrypt message
  final encrypted = encryption.encryptMessage(validationResult.sanitizedValue);

  // Save to Firestore
  await saveMessage(encrypted);
}
```

**Profile editing** (add validation):
```dart
// In edit_profile_screen.dart
import 'package:indira_love/core/services/validation_service.dart';

Future<void> saveProfile() async {
  // Validate display name
  final nameResult = validation.validateDisplayName(displayName);
  if (!nameResult.isValid) {
    showError(nameResult.message);
    return;
  }

  // Validate bio
  final bioResult = validation.validateBio(bio);
  if (!bioResult.isValid) {
    showError(bioResult.message);
    return;
  }

  // Save validated data
  await updateProfile(
    displayName: nameResult.sanitizedValue,
    bio: bioResult.sanitizedValue,
  );
}
```

### Task 8: Add Legal Document Links

**In settings page**:
```dart
ListTile(
  leading: Icon(Icons.gavel),
  title: Text('Terms of Service'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TermsOfServicePage()),
  ),
),
ListTile(
  leading: Icon(Icons.privacy_tip),
  title: Text('Privacy Policy'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PrivacyPolicyPage()),
  ),
),
ListTile(
  leading: Icon(Icons.groups),
  title: Text('Community Guidelines'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CommunityGuidelinesPage()),
  ),
),
```

### Task 9: Add Data Export/Deletion Features

**In settings page**:
```dart
import 'package:indira_love/core/services/data_export_service.dart';
import 'package:indira_love/core/services/account_deletion_service.dart';

ListTile(
  leading: Icon(Icons.download),
  title: Text('Export My Data'),
  subtitle: Text('Download all your data (GDPR)'),
  onTap: () async {
    final url = await dataExport.exportUserDataToStorage(userId);
    // Show download link
  },
),

ListTile(
  leading: Icon(Icons.delete_forever),
  title: Text('Delete Account'),
  subtitle: Text('Permanently delete your account'),
  onTap: () async {
    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation();
    if (confirmed) {
      await accountDeletion.requestAccountDeletion(userId);
    }
  },
),
```

### Task 10: Update IAP Implementation

**Replace** `iap_service.dart` usage with `iap_service_improved.dart`:

1. Update imports in subscription screens
2. Test with sandbox environment
3. Verify server-side verification works
4. Monitor Firestore for fraudulent purchase attempts

## 🔒 Security Checklist

- [ ] All print() statements replaced with logger
- [ ] Firebase Crashlytics configured
- [ ] All user inputs validated and sanitized
- [ ] Messages encrypted before storage
- [ ] Rate limiting enabled on all critical actions
- [ ] IAP server-side verification deployed
- [ ] Legal documents accessible to users
- [ ] Data export functionality tested
- [ ] Account deletion with 30-day grace period
- [ ] Profanity filter list populated
- [ ] Security events logged to Firestore
- [ ] All API keys stored in Firebase config (not in code)

## 📊 Monitoring

**Firebase Console - Monitor these**:
1. Crashlytics: Crash-free users percentage
2. Analytics: User engagement metrics
3. Firestore: `security_events` collection
4. Firestore: `fraudulent_purchases` collection
5. Firestore: `receipt_verifications` collection
6. Cloud Functions: Execution logs and errors

## 🚀 Deployment Checklist

### Before Production Release:

1. [ ] Run `flutter clean && flutter pub get`
2. [ ] Replace all print() statements
3. [ ] Test all validation services
4. [ ] Test encryption/decryption
5. [ ] Test rate limiting
6. [ ] Test data export
7. [ ] Test account deletion
8. [ ] Deploy Cloud Functions
9. [ ] Configure Firebase API keys
10. [ ] Test IAP in sandbox
11. [ ] Enable Crashlytics in Firebase Console
12. [ ] Set up Firestore indexes
13. [ ] Populate profanity filter
14. [ ] Review and update legal documents with real company info
15. [ ] Set up monitoring and alerts
16. [ ] Create incident response plan
17. [ ] Train support team on new features
18. [ ] Update privacy policy URLs in app stores
19. [ ] Test GDPR compliance features
20. [ ] Final security audit

## 📝 Next Steps

1. **Immediate**: Replace all print() statements (highest priority)
2. **Week 1**: Initialize all services in main.dart
3. **Week 1**: Deploy Cloud Functions
4. **Week 2**: Integrate validation in all forms
5. **Week 2**: Add encryption to messaging
6. **Week 3**: Add rate limiting to all actions
7. **Week 3**: Test data export/deletion
8. **Week 4**: Security audit and penetration testing
9. **Week 4**: Final production deployment

## 💡 Additional Recommendations

1. **Backup Strategy**: Implement automated Firestore backups
2. **Monitoring**: Set up Firebase Performance Monitoring
3. **Testing**: Add unit tests for all services
4. **Documentation**: Document all Cloud Functions
5. **Compliance**: Consult with legal team on GDPR/CCPA compliance
6. **Insurance**: Consider cyber liability insurance
7. **Audit**: Schedule regular security audits
8. **Training**: Train team on security best practices

## 🆘 Support

For questions or issues during migration:
- Review service documentation in code comments
- Check Firebase Console logs
- Test in development environment first
- Use logger service to debug issues
- Monitor Crashlytics for errors

---

**Last Updated**: January 2025
**Migration Status**: Services created, manual integration pending
