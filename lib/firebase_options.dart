import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
    apiKey: 'AIzaSyCeoHto0QBMzPWzsaPezpt7u3bjsWZ-Et0',
    appId: '1:246295355739:android:a9815b402f8482eab97a7e',
    messagingSenderId: '246295355739',
    projectId: 'visiontolegacy-16cb4',
    storageBucket: 'visiontolegacy-16cb4.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCBOcw92NrzSnzwzhZmoMWTgeGe_ItxeS4',
    appId: '1:246295355739:web:e37f0c0622d3d5f6b97a7e',
    messagingSenderId: '246295355739',
    projectId: 'visiontolegacy-16cb4',
    storageBucket: 'visiontolegacy-16cb4.firebasestorage.app',
    authDomain: 'visiontolegacy-16cb4.firebaseapp.com',
    measurementId: 'G-RDEV9W3SB6',
  );

  // iOS config — add GoogleService-Info.plist when building on Mac
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCeoHto0QBMzPWzsaPezpt7u3bjsWZ-Et0',
    appId: '1:246295355739:android:a9815b402f8482eab97a7e',
    messagingSenderId: '246295355739',
    projectId: 'visiontolegacy-16cb4',
    storageBucket: 'visiontolegacy-16cb4.firebasestorage.app',
  );
}
