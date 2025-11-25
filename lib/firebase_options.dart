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
    apiKey: 'AIzaSyAjdxfMYBvxlKNy54llLcNaxAKG4r9rfDo',
    appId: '1:918363978732:android:f3f8e534811dec74869ec9',
    messagingSenderId: '918363978732',
    projectId: 'indira-love',
    storageBucket: 'indira-love.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjdxfMYBvxlKNy54llLcNaxAKG4r9rfDo',
    appId: '1:918363978732:ios:f3f8e534811dec74869ec9',
    messagingSenderId: '918363978732',
    projectId: 'indira-love',
    storageBucket: 'indira-love.firebasestorage.app',
    iosBundleId: 'com.indiralove.dating',
  );
}
