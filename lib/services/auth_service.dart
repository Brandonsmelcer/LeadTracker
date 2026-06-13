import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    this._auth,
    this._firestore,
    bool? firebaseReady,
  }) : _firebaseReady = firebaseReady ?? Firebase.apps.isNotEmpty;

  final FirebaseAuth? _auth;
  final FirestoreService? _firestore;
  final bool _firebaseReady;

  bool get firebaseReady => _firebaseReady;

  FirebaseAuth? get _firebaseAuth =>
      _auth ?? (_firebaseReady ? FirebaseAuth.instance : null);

  FirestoreService? get _firebaseFirestore =>
      _firestore ?? (_firebaseReady ? FirestoreService() : null);

  static const debugPassword = 'Test1234!';

  static const Map<UserRole, String> debugEmails = {
    UserRole.admin: 'admin@test.com',
    UserRole.manager: 'manager@test.com',
    UserRole.associate: 'associate@test.com',
  };

  User? get firebaseUser => _firebaseAuth?.currentUser;
  bool get isSignedIn => firebaseUser != null;

  Future<void> signInWithEmail(
      String email, String password, AppProvider app) async {
    if (!firebaseReady || _firebaseAuth == null) {
      throw Exception('Firebase is not configured for this build.');
    }
    final cred = await _firebaseAuth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await _loadAndVerifyProfile(cred.user!.uid);
    if (profile == null) {
      await _firebaseAuth!.signOut();
      throw Exception('User profile not found or not approved.');
    }
    await _applyProfileToApp(app, profile);
    notifyListeners();
  }

  Future<void> debugSignInAs(UserRole role, AppProvider app) async {
    if (!kDebugMode) return;

    final email = debugEmails[role]!;
    const password = debugPassword;

    if (firebaseReady && _firebaseAuth != null && _firebaseFirestore != null) {
      UserCredential cred;
      try {
        cred = await _firebaseAuth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          cred = await _firebaseAuth!.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      String? managerId;
      if (role == UserRole.associate) {
        managerId = await _firebaseFirestore!
            .resolveManagerIdByEmail(debugEmails[UserRole.manager]!);
      }

      final profile = await _firebaseFirestore!.upsertUserProfile(
        uid: cred.user!.uid,
        email: email,
        name: _displayNameForRole(role),
        role: role,
        managerId: managerId,
        approved: true,
      );

      await _applyProfileToApp(app, profile);
      notifyListeners();
      return;
    }

    app.applyLocalDebugSession(
      role: role,
      email: email,
      uid: 'debug-${role.name}',
      name: _displayNameForRole(role),
    );
    notifyListeners();
  }

  Future<void> hydrateSession(AppProvider app) async {
    if (!firebaseReady) return;
    final user = firebaseUser;
    if (user == null) return;
    final profile = await _loadAndVerifyProfile(user.uid);
    if (profile != null) {
      await _applyProfileToApp(app, profile);
    } else {
      await signOut();
    }
    notifyListeners();
  }

  Future<UserProfile?> _loadAndVerifyProfile(String uid) async {
    final firestore = _firebaseFirestore;
    if (firestore == null) return null;
    final profile = await firestore.getUserProfile(uid);
    if (profile == null || !profile.approved) return null;
    return profile;
  }

  Future<void> _applyProfileToApp(
      AppProvider app, UserProfile profile) async {
    app.applySession(
      userId: profile.uid,
      name: profile.name,
      email: profile.email,
      role: profile.role,
      managerId: profile.managerId,
    );

    if (profile.role.canViewMasterMap && firebaseReady) {
      await _firebaseFirestore?.loadCountyLeads(app.applyCountyLeadFromRemote);
    }
  }

  Future<void> signOut() async {
    if (firebaseReady) {
      await _firebaseAuth?.signOut();
    }
    notifyListeners();
  }

  String _displayNameForRole(UserRole role) => switch (role) {
        UserRole.admin => 'Admin Tester',
        UserRole.manager => 'Manager Tester',
        UserRole.associate => 'Associate Tester',
      };
}
