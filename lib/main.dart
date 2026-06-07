import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const VisionToLegacyApp(),
    ),
  );
}

class VisionToLegacyApp extends StatelessWidget {
  const VisionToLegacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision To Legacy',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return const HomeScreen();
    }
    return AuthScreen(
      onAuthenticated: (AppUser user) {
        context.read<AppProvider>().setCurrentUser(user);
        setState(() => _authenticated = true);
      },
    );
  }
}
