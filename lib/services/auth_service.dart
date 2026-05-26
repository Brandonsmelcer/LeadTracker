import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (result.user == null) return null;
    return _getAppUser(result.user!.uid);
  }

  Future<AppUser?> signUp(
      String email, String password, String name, UserRole role) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (result.user == null) return null;

    final user = AppUser(
      id: result.user!.uid,
      name: name,
      role: role,
    );

    await _db.collection('users').doc(user.id).set({
      'name': user.name,
      'role': user.role.name,
      'email': email,
      'managerId': user.managerId ?? '',
      'avatarColor': user.avatarColor ?? '',
      'homeState': '',
      'homeCounty': '',
    });

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Sign in to Vision To Legacy',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<AppUser?> biometricSignIn() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    final authenticated = await authenticateWithBiometrics();
    if (!authenticated) return null;

    return _getAppUser(fbUser.uid);
  }

  Future<AppUser?> _getAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return AppUser(
      id: uid,
      name: d['name'] ?? '',
      role: UserRole.values.firstWhere(
          (r) => r.name == d['role'],
          orElse: () => UserRole.associate),
      managerId: d['managerId'],
      avatarColor: d['avatarColor'],
      homeState: d['homeState'],
      homeCounty: d['homeCounty'],
    );
  }

  Future<AppUser?> getCurrentAppUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _getAppUser(fbUser.uid);
  }
}
