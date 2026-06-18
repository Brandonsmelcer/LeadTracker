import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Vision To Legacy.
///
/// iOS values are sourced from `ios/Runner/GoogleService-Info.plist`.
/// Override at build time with --dart-define=FIREBASE_* for other platforms.
class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBXcw7HDr-RVB9hWM2T2oGUV7I6Oo5HkzA',
  );
  static const String _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:246295355739:ios:7a405ef85342a8beb97a7e',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '246295355739',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'visiontolegacy-16cb4',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'visiontolegacy-16cb4.firebasestorage.app',
  );

  static bool get isConfigured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (!isConfigured) {
        throw UnsupportedError(
          'Firebase web requires --dart-define FIREBASE_* values.',
        );
      }
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain.isNotEmpty ? _authDomain : null,
        storageBucket: _storageBucket.isNotEmpty ? _storageBucket : null,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (!isConfigured) {
          throw UnsupportedError(
            'Firebase Android requires google-services.json or --dart-define values.',
          );
        }
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket:
              _storageBucket.isNotEmpty ? _storageBucket : null,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket:
              _storageBucket.isNotEmpty ? _storageBucket : null,
          iosBundleId: 'com.visiontolegacy.leadTracker',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on $defaultTargetPlatform.',
        );
    }
  }
}
