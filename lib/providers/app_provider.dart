import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
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

  AppProvider() {
    _states = buildInitialStates();
    _currentUser = AppUser(
      name: 'Master Admin',
      role: UserRole.master,
      avatarColor: '#E94560',
    );
    _users.add(_currentUser);

    _channels.addAll([
      ChatChannel(name: 'general', icon: '💬'),
      ChatChannel(name: 'leads', icon: '📊'),
      ChatChannel(name: 'announcements', icon: '📢'),
      ChatChannel(name: 'team-chat', icon: '👥'),
    ]);
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

  int get totalLeads => _states.fold(0, (sum, s) => sum + s.totalLeads);
  int get totalCounties => _states.fold(0, (sum, s) => sum + s.counties.length);
  int get coveredCounties =>
      _states.fold(0, (sum, s) => sum + s.coveredCounties);

  List<AppUser> get managers =>
      _users.where((u) => u.role == UserRole.manager).toList();
  List<AppUser> get associates =>
      _users.where((u) => u.role == UserRole.associate).toList();
  List<SaleRecord> get sales => _sales;

  double get totalRevenue => _sales.fold(0, (sum, s) => sum + s.amount);

  double getTeamRevenue(String managerId) {
    return _sales
        .where((s) => s.managerId == managerId)
        .fold(0, (sum, s) => sum + s.amount);
  }

  double getPersonRevenue(String userId) {
    return _sales
        .where((s) => s.associateId == userId)
        .fold(0, (sum, s) => sum + s.amount);
  }

  List<SaleRecord> getPersonSales(String userId) {
    return _sales.where((s) => s.associateId == userId).toList();
  }

  List<AppUser> getTeamFor(String managerId) =>
      _users.where((u) => u.managerId == managerId).toList();

  // User management
  void addUser(String name, UserRole role, {String? managerId}) {
    final colors = ['#E94560', '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
                    '#00BCD4', '#FF5722', '#607D8B', '#795548', '#3F51B5'];
    _users.add(AppUser(
      name: name,
      role: role,
      managerId: managerId,
      avatarColor: colors[_users.length % colors.length],
    ));
    notifyListeners();
  }

  void removeUser(String userId) {
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
    notifyListeners();
  }

  // County operations
  void updateCountyLeads(String stateCode, String countyName, int count) {
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.leadCount = count;
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
    } else {
      _notes.add(note);
    }
    notifyListeners();
  }

  void addChannel(String name) {
    _channels.add(ChatChannel(name: name, icon: '#'));
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
    _sales.add(SaleRecord(
      associateId: associateId,
      managerId: managerId,
      amount: amount,
      description: description,
    ));
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
    notifyListeners();
  }
}
