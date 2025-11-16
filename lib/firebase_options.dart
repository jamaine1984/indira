import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzpr1foxR0Y9tA-0hk3aoP9XLFshcpYl0',
    appId: '1:410817495771:android:12345678901234567890',
    messagingSenderId: '410817495771',
    projectId: 'global-speed-dating',
    storageBucket: 'global-speed-dating.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzpr1foxR0Y9tA-0hk3aoP9XLFshcpYl0',
    appId: '1:410817495771:ios:12345678901234567890',
    messagingSenderId: '410817495771',
    projectId: 'global-speed-dating',
    storageBucket: 'global-speed-dating.firebasestorage.app',
    iosBundleId: 'com.global.speed.dating',
  );
}
