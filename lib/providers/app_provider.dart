import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../models/models.dart';
import '../data/county_data.dart';
import '../services/firestore_service.dart';

class AppProvider extends ChangeNotifier {
  late List<StateData> _states;
  final List<AppUser> _users = [];
  final List<Note> _notes = [];
  final List<ChatChannel> _channels = [];
  final List<LeadAssignment> _assignments = [];
  final List<Lead> _leads = [];
  FirestoreService? _firestore;
  AppUser? _currentUser;
  bool _isAuthenticated = false;

  AppProvider({bool bootstrapSession = false}) {
    _states = buildInitialStates();
    _initChannels();
    if (bootstrapSession) {
      _bootstrapAdminSession();
    }
  }

  /// Use in tests that expect an immediate admin session.
  factory AppProvider.testing() => AppProvider(bootstrapSession: true);

  void _initChannels() {
    _channels.addAll([
      ChatChannel(name: 'general', icon: '💬'),
      ChatChannel(name: 'leads', icon: '📊'),
      ChatChannel(name: 'announcements', icon: '📢'),
      ChatChannel(name: 'team-chat', icon: '👥'),
    ]);
  }

  void _bootstrapAdminSession() {
    _currentUser = AppUser(
      id: 'debug-admin',
      name: 'Admin',
      role: UserRole.admin,
      email: 'admin@test.com',
      avatarColor: '#E94560',
    );
    _users.add(_currentUser!);
    _seedDebugSampleLeads();
    _isAuthenticated = true;
  }

  // Getters
  List<StateData> get states => _states;
  List<AppUser> get users => _users;
  List<Note> get notes => _notes;
  List<ChatChannel> get channels => _channels;
  List<LeadAssignment> get assignments => _assignments;
  List<Lead> get leads => List.unmodifiable(_leads);
  AppUser get currentUser => _currentUser!;
  bool get isAuthenticated => _isAuthenticated;

  int get totalLeads => _states.fold(0, (sum, s) => sum + s.totalLeads);

  double get totalRevenue => _leads
      .where((l) => l.status == LeadStatus.sold)
      .fold(0.0, (sum, l) => sum + (l.saleAmount ?? 0));

  int get totalSalesCount =>
      _leads.where((l) => l.status == LeadStatus.sold).length;

  void setFirestoreService(FirestoreService? firestore) {
    _firestore = firestore;
  }
  int get totalCounties => _states.fold(0, (sum, s) => sum + s.counties.length);
  int get coveredCounties =>
      _states.fold(0, (sum, s) => sum + s.coveredCounties);

  /// Role-scoped lead totals for map headers and stats.
  int get visibleTotalLeads {
    int total = 0;
    for (final state in _states) {
      for (final county in state.counties) {
        total += mapVisibleLeadCount(county);
      }
    }
    return total;
  }

  int get visibleCoveredCounties {
    int total = 0;
    for (final state in _states) {
      for (final county in state.counties) {
        if (mapVisibleLeadCount(county) > 0) total++;
      }
    }
    return total;
  }

  Set<String> get _visibleAssigneeIds {
    if (!_isAuthenticated) return {};
    switch (_currentUser!.role) {
      case UserRole.admin:
        return _users.map((u) => u.id).toSet();
      case UserRole.manager:
        return {
          _currentUser!.id,
          ...getTeamFor(_currentUser!.id).map((u) => u.id),
        };
      case UserRole.associate:
        return {_currentUser!.id};
    }
  }

  List<AppUser> get admins =>
      _users.where((u) => u.role == UserRole.admin).toList();
  List<AppUser> get managers =>
      _users.where((u) => u.role == UserRole.manager).toList();
  List<AppUser> get associates =>
      _users.where((u) => u.role == UserRole.associate).toList();

  // Role permissions (delegated to current user — must match Firestore role)
  bool get canEditMap =>
      _isAuthenticated && _currentUser!.role.canEditMap;
  bool get canAccessMap =>
      _isAuthenticated && _currentUser!.role.canAccessMap;
  bool get canViewGlobalOverview =>
      _isAuthenticated && _currentUser!.role.canViewGlobalOverview;
  bool get canViewMasterMap =>
      _isAuthenticated && _currentUser!.role.canViewMasterMap;
  bool get canViewCombinedMap =>
      _isAuthenticated && _currentUser!.role.canViewCombinedMap;
  bool get canManageAllUsers =>
      _isAuthenticated && _currentUser!.role.canManageAllUsers;
  bool get canAccessAdminPortal =>
      _isAuthenticated && _currentUser!.role.canAccessAdminPortal;
  bool get canAccessTeamPortal =>
      _isAuthenticated && _currentUser!.role.canAccessTeamPortal;
  bool get canAddManagers =>
      _isAuthenticated && _currentUser!.role.canAddManagers;
  bool get canAddAssociates =>
      _isAuthenticated && _currentUser!.role.canAddAssociates;

  String get mapScopeLabel => switch (_currentUser?.role) {
        UserRole.admin => 'Admin Master Map',
        UserRole.manager => 'Manager Team Map',
        UserRole.associate => 'My Target Map',
        null => 'Map',
      };

  List<AppUser> getTeamFor(String managerId) =>
      _users.where((u) => u.managerId == managerId).toList();

  List<AppUser> get visibleAssociates {
    if (_currentUser!.role == UserRole.admin) return associates;
    if (_currentUser!.role == UserRole.manager) {
      return getTeamFor(_currentUser!.id);
    }
    return associates.where((u) => u.id == _currentUser!.id).toList();
  }

  int getTeamLeads(String managerId) {
    final teamIds = getTeamFor(managerId).map((u) => u.id).toSet();
    int total = 0;
    for (final state in _states) {
      for (final county in state.counties) {
        if (county.assignedTo != null && teamIds.contains(county.assignedTo)) {
          total += county.leadCount;
        }
      }
    }
    return total;
  }

  /// Lead count rendered on the map for the active role scope.
  int mapVisibleLeadCount(County county) {
    if (!_isAuthenticated) return 0;
    switch (_currentUser!.role) {
      case UserRole.admin:
        return county.leadCount;
      case UserRole.associate:
        return county.assignedTo == _currentUser!.id ? county.leadCount : 0;
      case UserRole.manager:
        if (county.assignedTo == null) return 0;
        return _visibleAssigneeIds.contains(county.assignedTo)
            ? county.leadCount
            : 0;
    }
  }

  bool isCountyVisibleOnMap(County county) {
    if (!_isAuthenticated) return false;
    if (_currentUser!.role == UserRole.admin) return true;
    return mapVisibleLeadCount(county) > 0;
  }

  bool isCountyInMapScope(String stateCode, String countyName) {
    final county = getCounty(stateCode, countyName);
    if (county == null) return false;
    return isCountyVisibleOnMap(county);
  }

  UserRole? roleForUser(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId).role;
    } catch (_) {
      return null;
    }
  }

  County? getCounty(String stateCode, String countyName) {
    try {
      final state = _states.firstWhere((s) => s.code == stateCode);
      return state.counties.firstWhere((c) => c.name == countyName);
    } catch (_) {
      return null;
    }
  }

  int getLeadCount(String stateCode, String countyName) {
    final county = getCounty(stateCode, countyName);
    if (county == null) return 0;
    return mapVisibleLeadCount(county);
  }

  void applySession({
    required String userId,
    required String name,
    required String email,
    required UserRole role,
    String? managerId,
  }) {
    _users.clear();
    _currentUser = AppUser(
      id: userId,
      name: name,
      role: role,
      email: email,
      managerId: managerId,
      avatarColor: '#E94560',
    );
    _users.add(_currentUser!);
    _isAuthenticated = true;
    _seedDebugSampleLeads();
    notifyListeners();
  }

  void applyLocalDebugSession({
    required UserRole role,
    required String email,
    required String uid,
    required String name,
  }) {
    _users.clear();
    _assignments.clear();
    _leads.clear();
    _resetCountyLeads();

    if (role == UserRole.admin) {
      applySession(userId: uid, name: name, email: email, role: role);
      return;
    }

    final admin = AppUser(
      id: 'debug-admin',
      name: 'Admin Tester',
      role: UserRole.admin,
      email: AuthEmails.admin,
      avatarColor: '#E94560',
    );

    if (role == UserRole.manager) {
      final manager = AppUser(
        id: uid,
        name: name,
        role: UserRole.manager,
        email: email,
        avatarColor: '#2196F3',
      );
      _users.addAll([admin, manager]);
      _currentUser = manager;
    } else {
      final manager = AppUser(
        id: 'debug-manager',
        name: 'Manager Tester',
        role: UserRole.manager,
        email: AuthEmails.manager,
        avatarColor: '#2196F3',
      );
      final associate = AppUser(
        id: uid,
        name: name,
        role: UserRole.associate,
        email: email,
        managerId: manager.id,
        avatarColor: '#4CAF50',
      );
      _users.addAll([admin, manager, associate]);
      _currentUser = associate;
    }

    _isAuthenticated = true;
    _seedDebugSampleLeads();
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _isAuthenticated = false;
    _users.clear();
    _assignments.clear();
    _leads.clear();
    _resetCountyLeads();
    notifyListeners();
  }

  void applyLeadFromRemote(Lead lead) {
    final index = _leads.indexWhere((l) => l.id == lead.id);
    if (index >= 0) {
      _leads[index] = lead;
    } else {
      _leads.add(lead);
    }
    notifyListeners();
  }

  void applyCountyLeadFromRemote(
    String stateCode,
    String countyName,
    int leadCount,
    String? assignedToId,
  ) {
    try {
      final state = _states.firstWhere((s) => s.code == stateCode);
      final county = state.counties.firstWhere((c) => c.name == countyName);
      county.leadCount = leadCount;
      county.assignedTo = assignedToId;
    } catch (_) {}
    notifyListeners();
  }

  void _resetCountyLeads() {
    for (final state in _states) {
      for (final county in state.counties) {
        county.leadCount = 0;
        county.assignedTo = null;
      }
    }
  }

  void _seedDebugSampleLeads() {
    if (!_isAuthenticated) return;

    final admin = _users.cast<AppUser?>().firstWhere(
          (u) => u?.role == UserRole.admin,
          orElse: () => null,
        );
    final manager = _users.cast<AppUser?>().firstWhere(
          (u) => u?.role == UserRole.manager,
          orElse: () => null,
        );
    final associate = _users.cast<AppUser?>().firstWhere(
          (u) => u?.role == UserRole.associate,
          orElse: () => null,
        );

    _assignCountyQuiet('TN', 'Davidson', manager?.id, 120);
    _assignCountyQuiet('TN', 'Shelby', associate?.id ?? manager?.id, 85);
    _assignCountyQuiet('KY', 'Jefferson', manager?.id, 64);
    _assignCountyQuiet('WV', 'Kanawha', associate?.id, 42);

    if (_currentUser!.role == UserRole.admin) {
      _assignCountyQuiet('TN', 'Knox', admin?.id, 200);
    }
  }

  void _assignCountyQuiet(
    String stateCode,
    String countyName,
    String? userId,
    int count,
  ) {
    final county = getCounty(stateCode, countyName);
    if (county == null) return;
    county.leadCount = count;
    county.assignedTo = userId;
  }

  // User management
  void addUser(String name, UserRole role, {String? managerId}) {
    if (!canAccessAdminPortal && role == UserRole.manager) return;
    if (role == UserRole.manager && !canAddManagers) return;
    if (role == UserRole.associate && !canAddAssociates) return;

    final effectiveManagerId = role == UserRole.associate
        ? (managerId ??
            (_currentUser!.role == UserRole.manager ? _currentUser!.id : null))
        : null;

    final colors = [
      '#E94560',
      '#4CAF50',
      '#2196F3',
      '#FF9800',
      '#9C27B0',
      '#00BCD4',
      '#FF5722',
      '#607D8B',
      '#795548',
      '#3F51B5'
    ];
    _users.add(AppUser(
      name: name,
      role: role,
      managerId: effectiveManagerId,
      avatarColor: colors[_users.length % colors.length],
    ));
    notifyListeners();
  }

  void removeUser(String userId) {
    if (!canManageAllUsers && _currentUser!.role == UserRole.manager) {
      final user = _users.cast<AppUser?>().firstWhere(
            (u) => u!.id == userId,
            orElse: () => null,
          );
      if (user == null || user.managerId != _currentUser!.id) return;
    } else if (!canManageAllUsers) {
      return;
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
    if (!canManageAllUsers) return;
    final user = _users.firstWhere((u) => u.id == userId);
    user.managerId = managerId;
    notifyListeners();
  }

  void updateCountyLeads(String stateCode, String countyName, int count) {
    if (!canEditMap) return;
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.leadCount = count;
    notifyListeners();
  }

  void assignCounty(String stateCode, String countyName, String? userId) {
    if (!canEditMap) return;
    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);
    county.assignedTo = userId;
    if (userId != null) {
      _assignments.add(LeadAssignment(
        countyId: county.id,
        assignedById: _currentUser!.id,
        assignedToId: userId,
        leadCount: county.leadCount,
      ));
    }
    notifyListeners();
  }

  /// Records a lead disposition outcome (sold, undecided, or not interested).
  Future<String?> recordLeadOutcome({
    required String associateId,
    required String stateCode,
    required String countyName,
    required LeadStatus disposition,
    double? saleAmount,
    String? closingNotes,
  }) async {
    if (!canEditMap && _currentUser!.role != UserRole.manager) {
      return 'You do not have permission to record outcomes.';
    }
    if (disposition == LeadStatus.sold &&
        (saleAmount == null || saleAmount <= 0)) {
      return 'Enter a valid sale amount for sold leads.';
    }

    final state = _states.firstWhere((s) => s.code == stateCode);
    final county = state.counties.firstWhere((c) => c.name == countyName);

    if (county.leadCount <= 0 &&
        disposition != LeadStatus.undecided &&
        !_leads.any((l) =>
            l.countyId == county.id &&
            l.assignedToId == associateId &&
            l.status.countsInActivePipeline)) {
      return 'No active leads available in this county.';
    }

    final trimmedNotes =
        closingNotes?.trim().isEmpty ?? true ? null : closingNotes!.trim();

    final lead = Lead(
      countyId: county.id,
      stateCode: stateCode,
      countyName: countyName,
      assignedToId: associateId,
      recordedById: _currentUser!.id,
      status: disposition,
      saleAmount: disposition == LeadStatus.sold ? saleAmount : null,
      closingNotes: trimmedNotes,
    );

    county.assignedTo = associateId;

    switch (disposition) {
      case LeadStatus.sold:
      case LeadStatus.notInterested:
        if (county.leadCount > 0) county.leadCount -= 1;
        break;
      case LeadStatus.undecided:
      case LeadStatus.active:
        break;
    }

    _leads.add(lead);
    _assignments.add(LeadAssignment(
      countyId: county.id,
      assignedById: _currentUser!.id,
      assignedToId: associateId,
      leadCount: 1,
      disposition: disposition,
      saleAmount: lead.saleAmount,
      closingNotes: trimmedNotes,
    ));

    try {
      await _firestore?.saveLead(lead);
      await _firestore?.upsertCountyLead(
        stateCode: stateCode,
        countyName: countyName,
        leadCount: county.leadCount,
        assignedToId: county.assignedTo,
      );
    } catch (_) {
      // Local state is updated even if remote sync fails.
    }

    notifyListeners();
    return null;
  }

  void addNote(String content, {String? channelId}) {
    final note = Note(
      authorId: _currentUser!.id,
      authorName: _currentUser!.name,
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

  String importCsv(String csvContent) {
    if (!canEditMap) return 'Only admins can import CSV data';
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

  List<PersonStats> getStats() {
    final stats = <String, PersonStats>{};
    for (final user in _users) {
      stats[user.id] = PersonStats(userId: user.id, userName: user.name);
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
    for (final lead in _leads) {
      final s = stats[lead.assignedToId];
      if (s == null) continue;
      switch (lead.status) {
        case LeadStatus.sold:
          s.totalSalesCount++;
          s.totalRevenue += lead.saleAmount ?? 0;
          break;
        case LeadStatus.undecided:
          s.undecidedCount++;
          break;
        case LeadStatus.active:
        case LeadStatus.notInterested:
          break;
      }
    }
    return stats.values.toList()
      ..sort((a, b) {
        final revenueCompare = b.totalRevenue.compareTo(a.totalRevenue);
        if (revenueCompare != 0) return revenueCompare;
        return b.totalLeadsAssigned.compareTo(a.totalLeadsAssigned);
      });
  }
}

/// Shared debug account emails (also used by AuthService).
class AuthEmails {
  static const admin = 'admin@test.com';
  static const manager = 'manager@test.com';
  static const associate = 'associate@test.com';
}
