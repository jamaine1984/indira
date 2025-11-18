# Production Services - Quick Reference Guide

## 🚀 Quick Start

### Initialization (in main.dart)
```dart
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/validation_service.dart';
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize services (order matters!)
  await logger.initialize();
  await validation.initialize();
  await encryption.initialize();
  await analytics.initialize();
  await rateLimiter.initialize();

  runApp(const MyApp());
}
```

---

## 📝 Logger Service

### Usage
```dart
import 'package:indira_love/core/services/logger_service.dart';

// Debug (only in debug mode)
logger.debug('User tapped button');

// Info
logger.info('User logged in successfully');

// Warning
logger.warning('API response slow', error: slowResponseTime);

// Error
logger.error('Failed to load data', error: e, stackTrace: stackTrace);

// Fatal (causes crash report)
logger.fatal('Critical error', error: e, stackTrace: stackTrace);

// Security events
logger.logSecurityEvent('Login attempt from new device', userId: userId);

// User actions (audit trail)
logger.logUserAction('profile_updated', userId: userId, details: {...});

// Network requests
logger.logNetworkRequest('/api/users', 'GET', statusCode: 200);
```

### Features
- Automatic Crashlytics integration
- Multiple log levels
- Production-safe (debug logs only in debug mode)
- Stack trace capture
- Security event logging

---

## ✅ Validation Service

### Common Validations
```dart
import 'package:indira_love/core/services/validation_service.dart';

// Display name
final nameResult = validation.validateDisplayName(name);
if (!nameResult.isValid) {
  showError(nameResult.message);
} else {
  useName(nameResult.sanitizedValue);
}

// Bio
final bioResult = validation.validateBio(bio);

// Email
final emailResult = validation.validateEmail(email);

// Password
final passwordResult = validation.validatePassword(password);

// Message
final messageResult = validation.validateMessage(message);

// Age
final ageResult = validation.validateAge(age);

// Interests
final interestsResult = validation.validateInterests(interestsList);
```

### Utility Functions
```dart
// Sanitize text (remove HTML, scripts, XSS)
final clean = validation.sanitizeText(userInput);

// Check for profanity
bool hasProfanity = validation.containsProfanity(text);

// Check for scam keywords
bool isScam = validation.containsScamKeywords(text);

// Check for spam
bool isSpam = validation.isSpam(text);

// Sanitize filename
final safeName = validation.sanitizeFilename(filename);
```

### ValidationResult
```dart
class ValidationResult {
  final bool isValid;
  final String message;
  final dynamic sanitizedValue;
}
```

---

## 🔐 Encryption Service

### Message Encryption
```dart
import 'package:indira_love/core/services/encryption_service.dart';

// Encrypt message before saving
final encrypted = encryption.encryptMessage(plainTextMessage);
await saveToFirestore(encrypted);

// Decrypt message for display
final decrypted = encryption.decryptMessage(encryptedMessage);
displayToUser(decrypted);

// Encrypt with metadata
final messageDoc = encryption.encryptMessageWithMetadata(
  plainText,
  senderId,
  receiverId,
);
await firestore.collection('messages').add(messageDoc);

// Decrypt from Firestore doc
final plainText = encryption.decryptFromDocument(messageDoc);
```

### Advanced Features
```dart
// File encryption
final encryptedFile = encryption.encryptFileData(fileBytes);

// File decryption
final originalFile = encryption.decryptFileData(encryptedBytes);

// Generate secure token
final token = encryption.generateSecureToken(length: 32);

// Test encryption
bool working = encryption.testEncryption();

// Check if enabled
bool enabled = encryption.isEncryptionEnabled();
```

---

## 📊 Analytics Service

### User Events
```dart
import 'package:indira_love/core/services/analytics_service.dart';

// Authentication
await analytics.logSignUp('email');
await analytics.logLogin('google');
await analytics.logLogout();

// Onboarding
await analytics.logOnboardingStart();
await analytics.logOnboardingStep(1, 'profile_photo');
await analytics.logOnboardingComplete();

// Profile
await analytics.logProfileView(viewedUserId);
await analytics.logProfileEdit();
await analytics.logPhotoUpload(3);

// Discovery
await analytics.logSwipeRight(userId);
await analytics.logSwipeLeft(userId);
await analytics.logSuperlike(userId);
await analytics.logBoostActivated(60);

// Matches
await analytics.logMatch(matchedUserId);
await analytics.logUnmatch(unmatchedUserId);

// Messaging
await analytics.logMessageSent(receiverId, 'text');
await analytics.logVoiceMessageSent(durationSeconds);
await analytics.logConversationStarted(withUserId);

// Gifts
await analytics.logGiftSent(giftId, receiverId, cost);
await analytics.logGiftReceived(giftId, senderId);

// Subscriptions
await analytics.logSubscriptionPurchase('gold', 9.99);
await analytics.logSubscriptionCancel('gold');

// Verification
await analytics.logVerificationStart('photo');
await analytics.logVerificationComplete('photo');

// Safety
await analytics.logUserReported(reportedUserId, 'spam');
await analytics.logUserBlocked(blockedUserId);

// Ads
await analytics.logAdWatched('rewarded', 'video_minutes');

// Engagement
await analytics.logSessionStart();
await analytics.logSessionEnd(durationSeconds);
await analytics.logScreenView('DiscoverScreen');
```

### User Properties
```dart
await analytics.setUserProperties(
  userId: userId,
  subscriptionTier: 'gold',
  gender: 'female',
  age: 25,
  location: 'New York',
);
```

---

## 🛡️ Rate Limiter Service

### Check Limits
```dart
import 'package:indira_love/core/services/rate_limiter_service.dart';

// Before swiping
final swipeResult = await rateLimiter.checkSwipeLimit(userId);
if (!swipeResult.allowed) {
  showError(swipeResult.reason);
  return;
}
// Proceed with swipe...

// Before liking
final likeResult = await rateLimiter.checkLikeLimit(userId);

// Before superliking
final superlikeResult = await rateLimiter.checkSuperlikeLimit(userId);

// Before messaging
final messageResult = await rateLimiter.checkMessageLimit(userId);

// Before reporting
final reportResult = await rateLimiter.checkReportLimit(userId);

// Before profile update
final updateResult = await rateLimiter.checkProfileUpdateLimit(userId);

// Before photo upload
final photoResult = await rateLimiter.checkPhotoUploadLimit(userId);

// Before sending gift
final giftResult = await rateLimiter.checkGiftLimit(userId);
```

### With Premium Tiers
```dart
final result = await rateLimiter.checkLimitWithTier(
  userId: userId,
  action: 'swipe',
  subscriptionTier: 'gold', // 2x limits
  dayLimit: 500,
);
```

### Ban Management
```dart
// Check if banned
bool isBanned = await rateLimiter.isUserBanned(userId);

// Ban user
await rateLimiter.banUser(userId, 24, 'Spam violation');

// Unban user
await rateLimiter.unbanUser(userId);

// Get remaining actions
final remaining = await rateLimiter.getRemainingActions(userId);
print('Swipes remaining: ${remaining['swipes_remaining_today']}');
```

### RateLimitResult
```dart
class RateLimitResult {
  final bool allowed;
  final String reason;
  final int? retryAfter; // seconds
  final int? currentCount;
  final int? limit;
}
```

---

## 💾 Data Export Service

### Export User Data
```dart
import 'package:indira_love/core/services/data_export_service.dart';

// Export to JSON
final data = await dataExport.exportUserData(userId);

// Export to file
final file = await dataExport.exportUserDataToFile(userId);

// Export to Firebase Storage (get download URL)
final url = await dataExport.exportUserDataToStorage(userId);

// Show URL to user
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Your Data Export'),
    content: Text('Download: $url\nExpires in 7 days'),
  ),
);

// Get export history
final history = await dataExport.getExportHistory(userId);

// Privacy report
final report = await dataExport.generatePrivacyReport(userId);
```

---

## 🗑️ Account Deletion Service

### Delete Account
```dart
import 'package:indira_love/core/services/account_deletion_service.dart';

// Request deletion (30-day grace period)
await accountDeletion.requestAccountDeletion(userId);

// Cancel deletion request
await accountDeletion.cancelAccountDeletion(userId);

// Immediate deletion (requires password)
await accountDeletion.deleteUserAccount(userId, password);

// Get deletion status
final status = await accountDeletion.getDeletionStatus(userId);
if (status?['status'] == 'pending_deletion') {
  showWarning('Account scheduled for deletion on ${status['scheduled_date']}');
}

// Delete specific data category
await accountDeletion.deleteDataCategory(userId, 'messages');
await accountDeletion.deleteDataCategory(userId, 'photos');
await accountDeletion.deleteDataCategory(userId, 'location');
```

---

## 💳 Improved IAP Service

### Purchase Flow
```dart
import 'package:indira_love/core/services/iap_service_improved.dart';

// Initialize
await iapService.initialize();

// Load products
final products = iapService.products;

// Purchase
final success = await iapService.purchase('indira_love_gold_monthly');

// Restore purchases
await iapService.restorePurchases();

// Check subscription status
final status = await iapService.getSubscriptionStatus();
if (status['active']) {
  print('Subscription: ${status['tier']}');
  print('Expires: ${status['expiryDate']}');
}

// Get specific product
final product = iapService.getProduct('indira_love_gold_monthly');
if (product != null) {
  print('Price: ${product.price}');
}
```

---

## 📄 Legal Documents

### Navigation
```dart
import 'package:indira_love/features/legal/terms_of_service.dart';
import 'package:indira_love/features/legal/privacy_policy.dart';
import 'package:indira_love/features/legal/community_guidelines.dart';

// Navigate to documents
Navigator.push(context, MaterialPageRoute(
  builder: (_) => TermsOfServicePage(),
));

Navigator.push(context, MaterialPageRoute(
  builder: (_) => PrivacyPolicyPage(),
));

Navigator.push(context, MaterialPageRoute(
  builder: (_) => CommunityGuidelinesPage(),
));
```

---

## 🔄 Complete Integration Example

### Message Sending with All Services
```dart
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/validation_service.dart';
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';

Future<void> sendMessage(String text, String receiverId) async {
  try {
    // 1. Validate message
    final validationResult = validation.validateMessage(text);
    if (!validationResult.isValid) {
      logger.warning('Message validation failed', tag: 'messaging');
      showError(validationResult.message);
      return;
    }

    // 2. Check rate limit
    final rateLimitResult = await rateLimiter.checkMessageLimit(currentUserId);
    if (!rateLimitResult.allowed) {
      logger.logSecurityEvent('Rate limit exceeded', userId: currentUserId);
      showError(rateLimitResult.reason);
      return;
    }

    // 3. Encrypt message
    final encryptedMessage = encryption.encryptMessage(
      validationResult.sanitizedValue,
    );

    // 4. Save to Firestore
    await firestore.collection('messages').add({
      'content': encryptedMessage,
      'encrypted': true,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 5. Log analytics
    await analytics.logMessageSent(receiverId, 'text');

    // 6. Log success
    logger.info('Message sent successfully', tag: 'messaging');

  } catch (e, stackTrace) {
    logger.error('Failed to send message', error: e, stackTrace: stackTrace);
    showError('Failed to send message. Please try again.');
  }
}
```

### Profile Update with All Services
```dart
Future<void> updateProfile({
  required String displayName,
  required String bio,
}) async {
  try {
    // 1. Check rate limit
    final rateLimitResult = await rateLimiter.checkProfileUpdateLimit(userId);
    if (!rateLimitResult.allowed) {
      showError(rateLimitResult.reason);
      return;
    }

    // 2. Validate display name
    final nameResult = validation.validateDisplayName(displayName);
    if (!nameResult.isValid) {
      showError(nameResult.message);
      return;
    }

    // 3. Validate bio
    final bioResult = validation.validateBio(bio);
    if (!bioResult.isValid) {
      showError(bioResult.message);
      return;
    }

    // 4. Update Firestore
    await firestore.collection('users').doc(userId).update({
      'displayName': nameResult.sanitizedValue,
      'bio': bioResult.sanitizedValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 5. Log analytics
    await analytics.logProfileEdit();

    // 6. Log success
    logger.info('Profile updated successfully');

    showSuccess('Profile updated!');

  } catch (e, stackTrace) {
    logger.error('Failed to update profile', error: e, stackTrace: stackTrace);
    showError('Failed to update profile');
  }
}
```

---

## ⚙️ Configuration

### Firestore Setup

#### app_config/profanity_filter
```javascript
{
  words: [
    "badword1",
    "badword2",
    "scam",
    "sugar daddy",
    // ... add more
  ]
}
```

#### app_config/encryption
```javascript
{
  master_key: "auto-generated",
  master_iv: "auto-generated",
  created_at: timestamp,
  algorithm: "AES-256-CBC"
}
```

### Firebase Functions Config
```bash
firebase functions:config:set apple.shared_secret="YOUR_SECRET"
firebase functions:config:set google.service_account='{"type":"service_account",...}'
```

---

## 🐛 Debugging

### Check Service Status
```dart
// Logger
bool loggerReady = logger.isCrashlyticsCollectionEnabled();

// Encryption
bool encryptionReady = encryption.isEncryptionEnabled();
bool encryptionWorks = encryption.testEncryption();

// IAP
bool iapReady = iapService.isAvailable;
```

### Common Issues

**Validation service not finding profanity**:
- Check Firestore `app_config/profanity_filter` exists
- Verify profanity list is populated

**Encryption failing**:
- Check Firestore `app_config/encryption` exists
- Run `encryption.testEncryption()` to verify

**Rate limiter not blocking**:
- Check Firestore `rate_limits` collection
- Verify service initialized

**IAP verification failing**:
- Check Cloud Function deployed
- Verify Cloud Function URL in code
- Check Cloud Function logs

---

## 📊 Monitoring

### Firestore Collections to Monitor
- `security_events` - Security incidents
- `fraudulent_purchases` - Failed IAP verifications
- `receipt_verifications` - All IAP verifications
- `rate_limits` - User action tracking
- `account_deletions` - Deletion audit trail

### Firebase Console
- **Crashlytics**: Monitor crash-free rate
- **Analytics**: Track user engagement
- **Functions**: Monitor execution errors
- **Firestore**: Watch for anomalies

---

## 🚨 Production Checklist

Before going live:
- [ ] All services initialized in main.dart
- [ ] Profanity filter populated
- [ ] Cloud Functions deployed
- [ ] Crashlytics configured
- [ ] All print() statements replaced
- [ ] Legal documents updated with real info
- [ ] IAP Cloud Function URL updated
- [ ] Firestore indexes created
- [ ] Security rules updated
- [ ] Testing completed

---

**Last Updated**: January 2025
**Documentation Version**: 1.0
