import 'dart:async';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../data/county_data.dart';

class AppProvider extends ChangeNotifier {
  late List<StateData> _states;
  final List<AppUser> _users = [];
  final List<Note> _notes = [];
  final List<ChatChannel> _channels = [];
  final List<LeadAssignment> _assignments = [];
  final List<SaleRecord> _sales = [];
  late AppUser _currentUser;
  bool _firestoreEnabled = false;
  FirebaseFirestore? _db;
  final List<StreamSubscription> _subs = [];

  AppProvider() {
    _states = buildInitialStates();
    _currentUser = AppUser(
      name: 'Master Admin',
      role: UserRole.master,
      avatarColor: '#E94560',
    );
    _users.add(_currentUser);

    _channels.addAll([
      ChatChannel(id: 'general', name: 'general', icon: '💬'),
      ChatChannel(id: 'leads', name: 'leads', icon: '📊'),
      ChatChannel(id: 'announcements', name: 'announcements', icon: '📢'),
      ChatChannel(id: 'team-chat', name: 'team-chat', icon: '👥'),
    ]);

    _initFirestore();
  }

  void _initFirestore() {
    try {
      _db = FirebaseFirestore.instance;
      _firestoreEnabled = true;
      _listenToUsers();
      _listenToCountyLeads();
      _listenToSales();
      for (final ch in _channels) {
        _listenToMessages(ch.id);
      }
    } catch (_) {
      _firestoreEnabled = false;
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  // Firestore listeners
  void _listenToUsers() {
    if (!_firestoreEnabled) return;
    final sub = _db!.collection('users').snapshots().listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final existing = _users.cast<AppUser?>().firstWhere(
            (u) => u!.id == doc.id, orElse: () => null);
        if (existing != null) {
          existing.name = d['name'] ?? existing.name;
          existing.role = UserRole.values.firstWhere(
              (r) => r.name == d['role'], orElse: () => existing.role);
          existing.managerId = d['managerId'];
          existing.avatarColor = d['avatarColor'];
          existing.homeState = d['homeState'];
          existing.homeCounty = d['homeCounty'];
        } else {
          _users.add(AppUser(
            id: doc.id,
            name: d['name'] ?? '',
            role: UserRole.values.firstWhere(
                (r) => r.name == d['role'], orElse: () => UserRole.associate),
            managerId: d['managerId'],
            avatarColor: d['avatarColor'],
            homeState: d['homeState'],
            homeCounty: d['homeCounty'],
          ));
        }
      }
      notifyListeners();
    });
    _subs.add(sub);
  }

  void _listenToCountyLeads() {
    if (!_firestoreEnabled) return;
    final sub = _db!.collection('county_leads').snapshots().listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final sc = d['stateCode'] as String? ?? '';
        final cn = d['countyName'] as String? ?? '';
        try {
          final state = _states.firstWhere((s) => s.code == sc);
          final county = state.counties.firstWhere(
              (c) => c.name.toLowerCase() == cn.toLowerCase());
          county.leadCount = d['leadCount'] ?? 0;
          county.assignedTo = d['assignedTo'];
          county.sentToManager = d['sentToManager'];
        } catch (_) {}
      }
      notifyListeners();
    });
    _subs.add(sub);
  }

  void _listenToSales() {
    if (!_firestoreEnabled) return;
    final sub = _db!.collection('sales').snapshots().listen((snap) {
      _sales.clear();
      for (final doc in snap.docs) {
        final d = doc.data();
        _sales.add(SaleRecord(
          id: doc.id,
          associateId: d['associateId'] ?? '',
          managerId: d['managerId'] ?? '',
          amount: (d['amount'] ?? 0).toDouble(),
          description: d['description'] ?? '',
          timestamp: d['timestamp'] is Timestamp
              ? (d['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(d['timestamp']?.toString() ?? '') ?? DateTime.now(),
        ));
      }
      notifyListeners();
    });
    _subs.add(sub);
  }

  void _listenToMessages(String channelId) {
    if (!_firestoreEnabled) return;
    final sub = _db!
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) {
      final channel = _channels.cast<ChatChannel?>().firstWhere(
          (c) => c!.id == channelId, orElse: () => null);
      if (channel == null) return;
      channel.messages.clear();
      for (final doc in snap.docs) {
        final d = doc.data();
        channel.messages.add(Note(
          id: doc.id,
          authorId: d['authorId'] ?? '',
          authorName: d['authorName'] ?? '',
          content: d['content'] ?? '',
          timestamp: d['timestamp'] is Timestamp
              ? (d['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(d['timestamp']?.toString() ?? '') ?? DateTime.now(),
          channelId: channelId,
        ));
      }
      notifyListeners();
    });
    _subs.add(sub);
  }

  // Firestore save helpers
  Future<void> _saveUser(AppUser user) async {
    if (!_firestoreEnabled) return;
    await _db!.collection('users').doc(user.id).set({
      'name': user.name,
      'role': user.role.name,
      'managerId': user.managerId ?? '',
      'avatarColor': user.avatarColor ?? '',
      'homeState': user.homeState ?? '',
      'homeCounty': user.homeCounty ?? '',
    });
  }

  Future<void> _saveCountyLead(String stateCode, County county) async {
    if (!_firestoreEnabled) return;
    await _db!.collection('county_leads').doc('${stateCode}_${county.name}').set({
      'stateCode': stateCode,
      'countyName': county.name,
      'leadCount': county.leadCount,
      'assignedTo': county.assignedTo,
      'sentToManager': county.sentToManager,
    });
  }

  void setCurrentUser(AppUser user) {
    if (!_users.any((u) => u.id == user.id)) {
      _users.add(user);
    }
    _currentUser = user;
    notifyListeners();
  }

  // Getters
  List<StateData> get states => _states;
  List<AppUser> get users => _users;
  List<Note> get notes => _notes;
  List<ChatChannel> get channels => _channels;
  AppUser get currentUser => _currentUser;

  int get totalLeads => _states.fold(0, (acc, s) => acc + s.totalLeads);
  int get totalCounties => _states.fold(0, (acc, s) => acc + s.counties.length);
  int get coveredCounties =>
      _states.fold(0, (acc, s) => acc + s.coveredCounties);

  List<AppUser> get managers =>
      _users.where((u) => u.role == UserRole.manager).toList();
  List<AppUser> get associates =>
      _users.where((u) => u.role == UserRole.associate).toList();
  List<SaleRecord> get sales => _sales;

  double get totalRevenue => _sales.fold(0.0, (acc, s) => acc + s.amount);

  double getTeamRevenue(String managerId) {
    return _sales
        .where((s) => s.managerId == managerId)
        .fold(0.0, (acc, s) => acc + s.amount);
  }

  double getPersonRevenue(String userId) {
    return _sales
        .where((s) => s.associateId == userId)
        .fold(0.0, (acc, s) => acc + s.amount);
  }

  List<SaleRecord> getPersonSales(String userId) {
    return _sales.where((s) => s.associateId == userId).toList();
  }

  List<AppUser> getTeamFor(String managerId) =>
      _users.where((u) => u.managerId == managerId).toList();

  // Leads visible to a manager (only ones master has sent them)
  List<County> getLeadsForManager(String managerId) {
    final result = <County>[];
    for (final state in _states) {
      for (final county in state.counties) {
        if (county.sentToManager == managerId) {
          result.add(county);
        }
      }
    }
    return result;
  }

  // User management
  void addUser(String name, UserRole role,
      {String? managerId, String? homeState, String? homeCounty}) {
    final colors = [
      '#E94560', '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
      '#00BCD4', '#FF5722', '#607D8B', '#795548', '#3F51B5'
    ];
    final user = AppUser(
      name: name,
      role: role,
      managerId: managerId,
      avatarColor: colors[_users.length % colors.length],
      homeState: homeState,
      homeCounty: homeCounty,
    );
    _users.add(user);
    _saveUser(user);
    notifyListeners();
  }

  void updateUser(String userId,
      {String? name, String? managerId, String? homeState, String? homeCounty}) {
    final user = _users.firstWhere((u) => u.id == userId);
    if (name != null) user.name = name;
    if (managerId != null) user.managerId = managerId;
    if (homeState != null) user.homeState = homeState;
    if (homeCounty != null) user.homeCounty = homeCounty;
    _saveUser(user);
    notifyListeners();
  }

  void removeUser(String userId) {
    if (_firestoreEnabled) {
      _db!.collection('users').doc(userId).delete();
    }
    _users.removeWhere((u) => u.id == userId);
    for (final u in _users) {
      if (u.managerId == userId) u.managerId = null;
    }
    for (final s in _states) {
      for (final c in s.counties) {
        if (c.assignedTo == userId) c.assignedTo = null;
      }
    }
    notifyListeners();
  }

  void assignUserToManager(String userId, String managerId) {
    final user = _users.firstWhere((u) => u.id == userId);
    user.managerId = managerId;
    _saveUser(user);
    notifyListeners();
  }

  // County operations
  void updateCountyLeads(String stateCode, String countyName, int count) {
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.leadCount = count;
    _saveCountyLead(stateCode, county);
    notifyListeners();
  }

  void assignCounty(String stateCode, String countyName, String? userId) {
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.assignedTo = userId;
    if (userId != null) {
      _assignments.add(LeadAssignment(
        countyId: county.id,
        assignedById: _currentUser.id,
        assignedToId: userId,
        leadCount: county.leadCount,
      ));
    }
    _saveCountyLead(stateCode, county);
    notifyListeners();
  }

  // Send leads to a specific manager (master only)
  void sendLeadsToManager(
      String stateCode, String countyName, String managerId) {
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.sentToManager = managerId;
    _saveCountyLead(stateCode, county);
    notifyListeners();
  }

  // Notes / Chat
  void addNote(String content, {String? channelId}) {
    final note = Note(
      authorId: _currentUser.id,
      authorName: _currentUser.name,
      content: content,
      channelId: channelId,
    );
    if (channelId != null) {
      final channel = _channels.firstWhere((c) => c.id == channelId);
      channel.messages.add(note);
      if (_firestoreEnabled) {
        _db!
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
    } else {
      _notes.add(note);
    }
    notifyListeners();
  }

  void addChannel(String name) {
    final channel = ChatChannel(name: name, icon: '#');
    _channels.add(channel);
    _listenToMessages(channel.id);
    notifyListeners();
  }

  // CSV Import
  String importCsv(String csvContent) {
    try {
      final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
      if (rows.isEmpty) return 'CSV file is empty';

      int imported = 0;
      int skipped = 0;

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].length < 3) {
          skipped++;
          continue;
        }
        final stateCode = rows[i][0].toString().trim().toUpperCase();
        final countyName = rows[i][1].toString().trim();
        final leads = int.tryParse(rows[i][2].toString().trim()) ?? 0;

        try {
          final state = _states.firstWhere((s) => s.code == stateCode);
          final county = state.counties.firstWhere(
            (c) => c.name.toLowerCase() == countyName.toLowerCase(),
          );
          county.leadCount += leads;
          if (rows[i].length > 3) {
            final assigneeName = rows[i][3].toString().trim();
            if (assigneeName.isNotEmpty) {
              final user = _users.cast<AppUser?>().firstWhere(
                (u) => u!.name.toLowerCase() == assigneeName.toLowerCase(),
                orElse: () => null,
              );
              if (user != null) county.assignedTo = user.id;
            }
          }
          _saveCountyLead(stateCode, county);
          imported++;
        } catch (_) {
          skipped++;
        }
      }

      notifyListeners();
      return 'Imported $imported rows ($skipped skipped)';
    } catch (e) {
      return 'Error parsing CSV: $e';
    }
  }

  // Sales
  void recordSale(String associateId, String managerId, double amount,
      {String description = ''}) {
    final sale = SaleRecord(
      associateId: associateId,
      managerId: managerId,
      amount: amount,
      description: description,
    );
    _sales.add(sale);
    if (_firestoreEnabled) {
      _db!.collection('sales').doc(sale.id).set({
        'associateId': sale.associateId,
        'managerId': sale.managerId,
        'amount': sale.amount,
        'description': sale.description,
        'timestamp': sale.timestamp.toIso8601String(),
      });
    }
    notifyListeners();
  }

  // Stats
  List<PersonStats> getStats() {
    final stats = <String, PersonStats>{};
    for (final user in _users) {
      stats[user.id] = PersonStats(
          userId: user.id, userName: user.name, role: user.role);
    }
    for (final state in _states) {
      for (final county in state.counties) {
        if (county.assignedTo != null && stats.containsKey(county.assignedTo)) {
          final s = stats[county.assignedTo]!;
          s.totalLeadsAssigned += county.leadCount;
          s.countiesWorked++;
          s.leadsByState[state.code] =
              (s.leadsByState[state.code] ?? 0) + county.leadCount;
        }
      }
    }
    for (final sale in _sales) {
      if (stats.containsKey(sale.associateId)) {
        stats[sale.associateId]!.totalSales += sale.amount;
        stats[sale.associateId]!.salesCount++;
      }
    }
    return stats.values.toList()
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));
  }

  // Delegation
  void delegateLeads(String fromUserId, String toUserId, String stateCode,
      String countyName, int count) {
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.assignedTo = toUserId;
    county.leadCount = count;
    _assignments.add(LeadAssignment(
      countyId: county.id,
      assignedById: fromUserId,
      assignedToId: toUserId,
      leadCount: count,
    ));
    _saveCountyLead(stateCode, county);
    notifyListeners();
  }
}
