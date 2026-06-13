import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const VisionToLegacyApp(),
    ),
  );
}

/// Must complete before [runApp], providers, [AuthService], or [MaterialApp].
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
    return;
  }

  // Fallback for google-services.json / GoogleService-Info.plist without
  // --dart-define values.
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  } catch (_) {
    // Firebase not configured for this build.
  }
}

class VisionToLegacyApp extends StatelessWidget {
  const VisionToLegacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision To Legacy',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hydrating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final auth = context.read<AuthService>();
    final app = context.read<AppProvider>();
    if (auth.firebaseReady && auth.isSignedIn) {
      await auth.hydrateSession(app);
    }
    if (mounted) setState(() => _hydrating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_hydrating) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
