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

  // Web config — register a web app in Firebase Console to get these values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeoHto0QBMzPWzsaPezpt7u3bjsWZ-Et0',
    appId: '1:246295355739:android:a9815b402f8482eab97a7e',
    messagingSenderId: '246295355739',
    projectId: 'visiontolegacy-16cb4',
    storageBucket: 'visiontolegacy-16cb4.firebasestorage.app',
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
