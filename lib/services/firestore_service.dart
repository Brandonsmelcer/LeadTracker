import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users
  CollectionReference get _usersRef => _db.collection('users');

  Future<void> saveUser(AppUser user) async {
    await _usersRef.doc(user.id).set({
      'name': user.name,
      'role': user.role.name,
      'managerId': user.managerId,
      'avatarColor': user.avatarColor,
      'homeState': user.homeState,
      'homeCounty': user.homeCounty,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _usersRef.doc(userId).delete();
  }

  Stream<List<AppUser>> watchUsers() {
    return _usersRef.snapshots().map((snap) => snap.docs.map((doc) {
          final d = doc.data()! as Map<String, dynamic>;
          return AppUser(
            id: doc.id,
            name: d['name'] ?? '',
            role: UserRole.values.firstWhere(
                (r) => r.name == d['role'],
                orElse: () => UserRole.associate),
            managerId: d['managerId'],
            avatarColor: d['avatarColor'],
          );
        }).toList());
  }

  // County Leads
  CollectionReference get _leadsRef => _db.collection('county_leads');

  Future<void> saveCountyLead(
      String stateCode, String countyName, int leadCount, String? assignedTo) async {
    final docId = '${stateCode}_$countyName';
    await _leadsRef.doc(docId).set({
      'stateCode': stateCode,
      'countyName': countyName,
      'leadCount': leadCount,
      'assignedTo': assignedTo,
    });
  }

  Stream<List<Map<String, dynamic>>> watchCountyLeads() {
    return _leadsRef.snapshots().map((snap) => snap.docs.map((doc) {
          final d = doc.data()! as Map<String, dynamic>;
          return {
            'stateCode': d['stateCode'] ?? '',
            'countyName': d['countyName'] ?? '',
            'leadCount': d['leadCount'] ?? 0,
            'assignedTo': d['assignedTo'],
          };
        }).toList());
  }

  // Sales
  CollectionReference get _salesRef => _db.collection('sales');

  Future<void> recordSale(SaleRecord sale) async {
    await _salesRef.doc(sale.id).set({
      'associateId': sale.associateId,
      'managerId': sale.managerId,
      'amount': sale.amount,
      'description': sale.description,
      'timestamp': sale.timestamp.toIso8601String(),
    });
  }

  Stream<List<SaleRecord>> watchSales() {
    return _salesRef.orderBy('timestamp', descending: true).snapshots().map(
        (snap) => snap.docs.map((doc) {
              final d = doc.data()! as Map<String, dynamic>;
              return SaleRecord(
                id: doc.id,
                associateId: d['associateId'] ?? '',
                managerId: d['managerId'] ?? '',
                amount: (d['amount'] ?? 0).toDouble(),
                description: d['description'] ?? '',
                timestamp: DateTime.tryParse(d['timestamp'] ?? '') ?? DateTime.now(),
              );
            }).toList());
  }

  // Chat Messages
  Future<void> sendMessage(String channelId, Note note) async {
    await _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(note.id)
        .set({
      'authorId': note.authorId,
      'authorName': note.authorName,
      'content': note.content,
      'timestamp': note.timestamp.toIso8601String(),
    });
  }

  Stream<List<Note>> watchMessages(String channelId) {
    return _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return Note(
                id: doc.id,
                authorId: d['authorId'] ?? '',
                authorName: d['authorName'] ?? '',
                content: d['content'] ?? '',
                timestamp: DateTime.tryParse(d['timestamp'] ?? '') ?? DateTime.now(),
                channelId: channelId,
              );
            }).toList());
  }
}
