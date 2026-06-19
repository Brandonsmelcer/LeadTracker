import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? managerId;
  final bool approved;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.managerId,
    this.approved = false,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'User',
      role: userRoleFromFirestore(data['role'] as String?) ?? UserRole.associate,
      managerId: data['managerId'] as String?,
      approved: data['approved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.name,
        'managerId': managerId,
        'approved': approved,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class FirestoreService {
  FirestoreService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>>? get _users =>
      _db?.collection('users');

  CollectionReference<Map<String, dynamic>>? get _counties =>
      _db?.collection('county_leads');

  CollectionReference<Map<String, dynamic>>? get _leads =>
      _db?.collection('leads');

  Future<void> saveLead(Lead lead) async {
    final leads = _leads;
    if (leads == null) return;
    await leads.doc(lead.id).set({
      ...lead.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertCountyLead({
    required String stateCode,
    required String countyName,
    required int leadCount,
    String? assignedToId,
  }) async {
    final counties = _counties;
    if (counties == null) return;
    final docId = '${stateCode}_$countyName'.replaceAll(' ', '_');
    await counties.doc(docId).set({
      'stateCode': stateCode,
      'countyName': countyName,
      'leadCount': leadCount,
      'assignedToId': assignedToId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Loads individual lead disposition records into local provider state.
  Future<void> loadLeads(void Function(Lead lead) applyLead) async {
    final leads = _leads;
    if (leads == null) return;
    final snap = await leads.get();
    for (final doc in snap.docs) {
      applyLead(Lead.fromMap(doc.id, doc.data()));
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final users = _users;
    if (users == null) return null;
    final doc = await users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<UserProfile?> getUserProfileByEmail(String email) async {
    final users = _users;
    if (users == null) return null;
    final snap = await users
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Future<UserProfile> upsertUserProfile({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    String? managerId,
    bool approved = true,
  }) async {
    final users = _users;
    if (users == null) {
      throw StateError('Firestore is not available.');
    }
    final profile = UserProfile(
      uid: uid,
      email: email.toLowerCase(),
      name: name,
      role: role,
      managerId: managerId,
      approved: approved,
    );
    await users.doc(uid).set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  Future<String?> resolveManagerIdByEmail(String managerEmail) async {
    final profile = await getUserProfileByEmail(managerEmail);
    return profile?.uid;
  }

  /// Loads master county lead records into the local provider state.
  Future<void> loadCountyLeads(
    void Function(String stateCode, String countyName, int leadCount,
            String? assignedToId)
        applyLead,
  ) async {
    final counties = _counties;
    if (counties == null) return;
    final snap = await counties.get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final stateCode = data['stateCode'] as String?;
      final countyName = data['countyName'] as String?;
      final leadCount = (data['leadCount'] as num?)?.toInt() ?? 0;
      final assignedTo = data['assignedToId'] as String?;
      if (stateCode != null && countyName != null) {
        applyLead(stateCode, countyName, leadCount, assignedTo);
      }
    }
  }
}
