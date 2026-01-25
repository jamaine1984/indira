# iOS Production Configuration - Indira Love

## ✅ Completed Configuration Changes

### 1. Info.plist Updates (`ios/Runner/Info.plist`)

**✅ App Branding:**
- Changed display name from "Global Speed Dating" to "Indira Love"

**✅ Permission Descriptions (Updated for iOS App Store Review):**
- **Camera**: "Indira Love needs camera access to take profile photos and verification selfies."
- **Microphone**: "Indira Love needs microphone access to record voice messages."
- **Photo Library**: "Indira Love needs photo library access to upload profile pictures and Lovers Anonymous posts."
- **Location**: "Indira Love uses your location to find nearby singles."

**✅ Removed Video Calling Dependencies:**
- Removed ZegoCloud App ID and App Sign (no longer needed)
- Removed `voip` from background modes (kept `remote-notification` for push)

**✅ AdMob Configuration:**
- Added `GADApplicationIdentifier` key with placeholder
- **⚠️ ACTION REQUIRED**: Replace `ca-app-pub-7587025688858323~XXXXXXXXXX` with your actual iOS AdMob App ID

**📍 How to Get iOS AdMob App ID:**
1. Go to https://admob.google.com
2. Login with account: `ca-app-pub-7587025688858323`
3. Click "Apps" → "Add App" → "iOS"
4. Enter app name: "Indira Love"
5. Copy the **App ID** (format: `ca-app-pub-7587025688858323~1234567890`)
6. Update `Info.plist` line 83 with the real App ID

---

### 2. Launcher Icons (`pubspec.yaml`)

**✅ Enabled iOS Icons:**
- Changed `ios: false` to `ios: true`
- Uses `assets/icons/app_icon.png` for icon generation

**📍 Generate Icons:**
```bash
cd ~/indira
flutter pub run flutter_launcher_icons
```

---

## 🚀 Next Steps for iOS Deployment

### Step 1: Configure Xcode Project

**Open the project in Xcode:**
```bash
cd ~/indira
open ios/Runner.xcworkspace
```

**Configure Bundle Identifier:**
1. Select "Runner" in the left sidebar
2. Go to "General" tab
3. Update "Bundle Identifier" to: `com.yourdomain.indiralove`
   - Must be unique (check App Store Connect)
   - Example: `com.jamaine.indiralove`

**Configure Signing & Capabilities:**
1. In Xcode, go to "Signing & Capabilities" tab
2. Enable "Automatically manage signing"
3. Select your **Team** (Apple Developer account)
4. Xcode will auto-generate provisioning profiles

**Required Capabilities (Should Already Be Configured):**
- ✅ Push Notifications (for Firebase Cloud Messaging)
- ✅ Background Modes → Remote notifications

---

### Step 2: Update AdMob App ID

**In `ios/Runner/Info.plist` (line 83):**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-7587025688858323~YOUR_REAL_IOS_APP_ID</string>
```

Replace `YOUR_REAL_IOS_APP_ID` with the iOS App ID from AdMob console.

---

### Step 3: Build iOS App

**Clean previous builds:**
```bash
cd ~/indira
flutter clean
flutter pub get
```

**Run on iOS Simulator:**
```bash
flutter run -d ios
```

**Build for iOS Release:**
```bash
flutter build ios --release
```

---

### Step 4: Test on Physical iPhone Device

**Connect iPhone via USB, then:**
```bash
flutter run -d <device-id> --release
```

**Test these critical features on iOS:**
- [ ] User registration and login
- [ ] Profile creation with photo upload
- [ ] Discovery with swipe animations (smooth 60fps)
- [ ] Matching system
- [ ] Messaging with text, images, voice notes
- [ ] Lovers Anonymous posts with images
- [ ] AdMob ads display (banner, interstitial, rewarded)
- [ ] Push notifications
- [ ] In-app purchases (if applicable)
- [ ] Data export and account deletion (GDPR)

---

### Step 5: Submit to App Store

**Archive the app in Xcode:**
1. In Xcode, select **Product → Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Select **App Store Connect**
5. Follow submission workflow

**App Store Review Notes:**
- App does NOT use App Tracking Transparency (ATT)
- Uses contextual ads only (no cross-app tracking)
- Complies with Apple's privacy requirements
- All permissions have clear user-facing descriptions

---

## 🔍 iOS-Specific Optimizations

### Performance
- **60fps animations** during swipe gestures
- **Image caching** with `cached_network_image` package
- **Memory management** for extended sessions
- **Background fetch** for new matches

### Security
- **Keychain storage** for sensitive tokens (handled by Firebase)
- **SSL pinning** for API calls (Firebase handles this)
- **Biometric auth** (can add later with `local_auth` package)

### User Experience
- **Dark mode support** (check `AppTheme` configuration)
- **Haptic feedback** on swipes (can add with `flutter_vibrate`)
- **Pull-to-refresh** on discovery and matches
- **Offline mode** with cached data

---

## 📊 iOS vs Android Differences

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| **Push Notifications** | APNs (Firebase) | FCM | Both configured |
| **In-App Purchases** | StoreKit | Google Play Billing | Use `in_app_purchase` package |
| **Deep Linking** | Universal Links | App Links | Configure in Xcode/Android Manifest |
| **Background Processing** | Limited (10 min) | More flexible | iOS has stricter limits |
| **AdMob** | Separate App ID | Separate App ID | Must create iOS-specific ad units |

---

## ✅ Production Readiness Checklist

### Configuration
- [x] Info.plist updated with correct permissions
- [x] App display name changed to "Indira Love"
- [x] Video calling code removed
- [x] iOS launcher icons enabled
- [ ] Bundle identifier configured in Xcode
- [ ] AdMob iOS App ID added to Info.plist
- [ ] Signing & capabilities configured in Xcode

### Testing
- [ ] App builds without errors on iOS
- [ ] Runs on iOS simulator
- [ ] Tested on physical iPhone device
- [ ] All features work correctly
- [ ] Push notifications tested
- [ ] Ads load and display
- [ ] Performance is smooth (60fps)

### Deployment
- [ ] App archived in Xcode
- [ ] Screenshots prepared for App Store
- [ ] App Store description written
- [ ] Privacy policy URL configured
- [ ] Terms of service URL configured
- [ ] App submitted for review

---

## 🛠️ Troubleshooting

### Issue: "Code signing error"
**Solution:**
- Open Xcode → Signing & Capabilities
- Enable "Automatically manage signing"
- Select your Apple Developer team

### Issue: "Missing App ID"
**Solution:**
- Create app in App Store Connect first
- Use same bundle identifier in Xcode

### Issue: "AdMob ads not loading"
**Solution:**
- Verify AdMob iOS App ID is correct in Info.plist
- Create iOS-specific ad units in AdMob console
- Update `ad_config.dart` with iOS ad unit IDs

### Issue: "Firebase configuration missing"
**Solution:**
- Download `GoogleService-Info.plist` from Firebase console
- Add to `ios/Runner/` folder in Xcode
- Ensure it's added to target "Runner"

---

## 📚 Additional Resources

- **Apple Developer Portal**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **AdMob Console**: https://admob.google.com
- **Firebase Console**: https://console.firebase.google.com
- **Flutter iOS Deployment Guide**: https://docs.flutter.dev/deployment/ios

---

## 🎯 Next Task After iOS Configuration

Once iOS configuration is complete and tested, the remaining tasks are:

1. **Task 12**: Test app on iOS devices (in progress based on checklist above)
2. **Task 15**: Populate profanity filter in Firestore
3. **Task 4**: Replace print statements with LoggerService (79 files)

---

**Last Updated**: Configuration completed for iOS production deployment
**Platform Priority**: iOS-first (as requested), Android support for future update
