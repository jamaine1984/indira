# INDIRA LOVE - PRODUCTION LAUNCH GUIDE

**Last Updated:** November 18, 2025
**Status:** Ready for Production (with remaining fixes)
**Timeline:** 3-4 Days to Launch

---

## ✅ COMPLETED FIXES

### 1. AdMob Production IDs - DONE ✅
**Updated:** `.env` file
**App ID:** `ca-app-pub-7587025688858323~6036042883`
**Ad Unit ID:** `ca-app-pub-7587025688858323/9118884689`

All AdMob placeholders have been replaced with your production IDs.

---

## 🔧 REMAINING CRITICAL FIXES

### Fix 1: Configure Release Signing (2 hours)

**Current Issue:** Build.gradle uses debug signing for release builds
**Location:** `android/app/build.gradle:54`

**Step 1: Create Production Keystore**
```bash
cd C:\Users\koike\Downloads\indira\android\app

# Create keystore (YOU NEED TO DO THIS)
keytool -genkey -v -keystore indira-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias indira-key

# Enter details when prompted:
# - Password: [CREATE STRONG PASSWORD - SAVE IT!]
# - First and Last Name: Indira Dating
# - Organizational Unit: Development
# - Organization: Indira Love
# - City/Locality: [Your City]
# - State/Province: [Your State]
# - Country Code: [Your Country Code]
```

**Step 2: Create key.properties**
```bash
# Create file: android/key.properties
storePassword=[YOUR_KEYSTORE_PASSWORD]
keyPassword=[YOUR_KEY_PASSWORD]
keyAlias=indira-key
storeFile=indira-release-key.jks
```

**Step 3: Update build.gradle**

Add before `android {` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Add signing config inside `android {` block:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

Change buildTypes:
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release  // CHANGE FROM .debug
        minifyEnabled true
        shrinkResources true
    }
}
```

**Step 4: Secure Keystore**
```bash
# Add to .gitignore
echo "*.jks" >> .gitignore
echo "key.properties" >> .gitignore

# BACKUP KEYSTORE TO SAFE LOCATION (USB drive, cloud)
# YOU CANNOT PUBLISH UPDATES WITHOUT THIS FILE!
```

---

### Fix 2: Fix Package Name Consistency (30 minutes)

**Current Issue:** App uses `com.indiralove.dating` but Firebase config has `com.global.speed.dating`

**Option A: Update Firebase Project (Recommended)**
1. Go to Firebase Console (https://console.firebase.google.com)
2. Select "global-speed-dating" project
3. Go to Project Settings → General
4. Under "Your apps" → Android app
5. Either:
   - Add new Android app with package `com.indiralove.dating`
   - Or create new Firebase project named "indira-love"
6. Download new `google-services.json`
7. Replace `android/app/google-services.json`

**Option B: Change App Package Name (More Work)**
1. Update `android/app/build.gradle`: Change `namespace` and `applicationId` to `com.global.speed.dating`
2. Update `AndroidManifest.xml` package references
3. Rename Java/Kotlin package directories
4. NOT RECOMMENDED - stick with current package name

---

### Fix 3: Remove Video Calling (30 minutes)

**Current Status:** ZegoCloud packages commented out in `pubspec.yaml`

**To Completely Remove:**

1. **Delete ZegoCloud .env entries:**
```bash
# Remove from .env:
ZEGOCLOUD_APP_ID=...
ZEGOCLOUD_APP_SIGN=...
ZEGOCLOUD_SERVER_SECRET=...
```

2. **Ensure packages stay commented:**
```yaml
# pubspec.yaml - keep these commented:
# - zego_uikit_prebuilt_call: ^4.19.3
# - zego_uikit_signaling_plugin: ^2.19.3
```

3. **Hide video calling UI:**
```dart
// In any file that shows video call buttons, wrap with:
if (false) {  // Disable video calling for v1.0
  // Video call button code
}
```

**Alternative: Re-enable (4-8 hours)**
- Uncomment packages
- Run `flutter pub get`
- Fix any build errors
- Test thoroughly

---

### Fix 4: Secure .gitignore (5 minutes)

**Add these to `.gitignore`:**
```
# Keystore files
*.jks
*.keystore
key.properties

# Environment files
.env
.env.local
.env.production

# Firebase private keys
google-services.json
GoogleService-Info.plist
service-account.json
```

---

## 🎯 BUILD & TEST PROCESS

### Build Release APK

```bash
cd C:\Users\koike\Downloads\indira

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Test Release APK

```bash
# Install on test device
adb install build/app/outputs/flutter-apk/app-release.apk

# Test these critical flows:
# 1. Sign up with email
# 2. Google sign-in
# 3. Create profile
# 4. Discover users
# 5. Like/superlike
# 6. Send messages
# 7. View ads
# 8. Purchase subscription (test mode)
# 9. Send gifts
# 10. Report user
```

---

## 📱 GOOGLE PLAY STORE CHECKLIST

### App Listing Requirements

**Before Uploading:**
- [ ] App name: "Indira Love"
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (min 2, recommended 8)
- [ ] Privacy Policy URL (must be live)
- [ ] Content rating questionnaire
- [ ] Target age: 18+

**App Details:**
- Category: Dating
- Contains ads: Yes
- In-app purchases: Yes
- Target audience: Adults 18+

### Release Notes (v1.0.0)

```
Welcome to Indira Love!

Features:
• Create your profile with photos and bio
• Discover compatible matches
• Like and Superlike users
• Real-time messaging
• Send virtual gifts
• Boost your profile
• Daily missions and rewards
• Subscription plans for premium features

Join thousands finding love with Indira!
```

---

## 🔒 SECURITY RECOMMENDATIONS

### Before Launch:

1. **Review Firestore Rules:**
```bash
cd C:\Users\koike\Downloads\indira
cat firestore.rules
# Verify all collections have proper authentication
```

2. **Check Storage Rules:**
```bash
cat storage.rules
# Verify file size limits (10MB images, 50MB videos)
```

3. **Review Privacy Policy:**
- Ensure GDPR compliance
- Include data collection disclosure
- Link from app settings

4. **Enable Google Play App Signing:**
- Let Google manage your signing key
- Provides additional security

---

## 📊 POST-LAUNCH MONITORING

### Week 1 Tasks:

**Daily Monitoring:**
- Check Firebase Crashlytics for crashes
- Monitor Firestore usage (stay under quotas)
- Review Google Play reviews/ratings
- Check AdMob earnings

**Firebase Console:**
- Analytics → Users (DAU/MAU)
- Cloud Functions → Logs (errors)
- Firestore → Usage (read/write counts)

**Performance Metrics:**
- App startup time
- Discovery page load time
- Message send/receive latency
- Ad fill rate

---

## 🚨 ROLLBACK PLAN

### If Critical Issues Found:

1. **Unpublish from Play Store** (temporarily)
2. **Fix issues in codebase**
3. **Increment version code** (e.g., 1 → 2)
4. **Build new APK**
5. **Upload as update**

### Emergency Contacts:
- Firebase Support: https://firebase.google.com/support
- AdMob Help: https://support.google.com/admob
- Play Console Help: https://support.google.com/googleplay/android-developer

---

## ✅ FINAL PRE-LAUNCH CHECKLIST

**Code:**
- [ ] Production AdMob IDs configured ✅
- [ ] Release signing configured
- [ ] Package name consistency fixed
- [ ] Video calling removed/fixed
- [ ] .env excluded from git
- [ ] Debug prints removed
- [ ] All TODOs addressed

**Firebase:**
- [ ] Firestore rules reviewed ✅
- [ ] Storage rules reviewed ✅
- [ ] Cloud Functions deployed ✅
- [ ] Indexes created ✅
- [ ] Analytics enabled ✅

**Testing:**
- [ ] Auth flows tested
- [ ] Messaging tested
- [ ] Matching/discovery tested
- [ ] Ads displaying correctly
- [ ] IAP tested (sandbox mode)
- [ ] Crash reporting works

**Legal:**
- [ ] Privacy Policy live
- [ ] Terms of Service live
- [ ] Age restriction (18+) enforced
- [ ] Content rating completed

**Play Store:**
- [ ] App listing created
- [ ] Screenshots uploaded
- [ ] Release APK uploaded
- [ ] Internal testing complete
- [ ] Production release scheduled

---

## 🎉 LAUNCH DAY TASKS

1. **Monitor Firebase in real-time**
2. **Respond to reviews quickly**
3. **Check for crashes every hour**
4. **Post on social media**
5. **Prepare support email responses**
6. **Have emergency contact ready**

---

## 📅 SUGGESTED TIMELINE

### Day 1 (Today)
- ✅ Update AdMob IDs (DONE)
- ⏳ Configure release signing
- ⏳ Fix package name
- ⏳ Build test APK

### Day 2
- Test release APK thoroughly
- Create Play Store listing
- Upload screenshots
- Write app descriptions

### Day 3
- Internal testing with team
- Fix any bugs found
- Create release APK
- Upload to Play Console (internal testing)

### Day 4 (Launch)
- Move to production
- Monitor closely
- Respond to feedback
- Celebrate! 🎉

---

## 💡 QUICK START (Next 2 Hours)

```bash
# 1. Create keystore (5 min)
cd android/app
keytool -genkey -v -keystore indira-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias indira-key

# 2. Create key.properties (2 min)
# [Create file with your passwords]

# 3. Update build.gradle (10 min)
# [Add signing config as described above]

# 4. Test build (30 min)
cd ../..
flutter clean
flutter pub get
flutter build apk --release

# 5. Test on device (60 min)
adb install build/app/outputs/flutter-apk/app-release.apk
# [Test all features]
```

---

## 🆘 NEED HELP?

**Common Issues:**

**"Execution failed for task ':app:lintVitalAnalyzeRelease'"**
- Add to `android/app/build.gradle`:
```gradle
lintOptions {
    checkReleaseBuilds false
}
```

**"Cannot find google-services.json"**
- Download from Firebase Console
- Place in `android/app/`

**"Keystore file not found"**
- Ensure `storeFile` path is correct in `key.properties`
- Use relative path: `indira-release-key.jks`

---

## 📞 SUPPORT RESOURCES

- Flutter Docs: https://docs.flutter.dev
- Firebase Console: https://console.firebase.google.com
- Play Console: https://play.google.com/console
- AdMob: https://apps.admob.com

---

**Good Luck with Launch! 🚀**
