import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { admin, manager, associate }

UserRole? userRoleFromFirestore(String? value) {
  switch (value?.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'associate':
      return UserRole.associate;
    default:
      return null;
  }
}

extension UserRolePermissions on UserRole {
  bool get canEditMap => this == UserRole.admin;
  bool get canViewGlobalOverview => this == UserRole.admin;
  bool get canViewMasterMap => this == UserRole.admin;
  bool get canViewCombinedMap => this == UserRole.admin;
  bool get canManageAllUsers => this == UserRole.admin;
  bool get canAccessAdminPortal => this == UserRole.admin;
  bool get canAccessTeamPortal =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canAddManagers => this == UserRole.admin;
  bool get canAddAssociates =>
      this == UserRole.admin || this == UserRole.manager;
}

class AppUser {
  final String id;
  String name;
  UserRole role;
  String? email;
  String? managerId;
  String? avatarColor;

  AppUser({
    String? id,
    required this.name,
    required this.role,
    this.email,
    this.managerId,
    this.avatarColor,
  }) : id = id ?? _uuid.v4();

  int get totalLeads => 0;
}

class County {
  final String name;
  final String stateCode;
  int leadCount;
  String? assignedTo;

  County({
    required this.name,
    required this.stateCode,
    this.leadCount = 0,
    this.assignedTo,
  });

  String get id => '${stateCode}_$name';
}

class StateData {
  final String name;
  final String code;
  final List<County> counties;

  StateData({
    required this.name,
    required this.code,
    required this.counties,
  });

  int get totalLeads => counties.fold(0, (sum, c) => sum + c.leadCount);
  int get coveredCounties => counties.where((c) => c.leadCount > 0).length;
  double get coveragePercent =>
      counties.isEmpty ? 0 : (coveredCounties / counties.length) * 100;
}

class Note {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final String? channelId;

  Note({
    String? id,
    required this.authorId,
    required this.authorName,
    required this.content,
    DateTime? timestamp,
    this.channelId,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class ChatChannel {
  final String id;
  final String name;
  final String icon;
  final List<Note> messages;

  ChatChannel({
    String? id,
    required this.name,
    this.icon = '#',
    List<Note>? messages,
  })  : id = id ?? _uuid.v4(),
        messages = messages ?? [];
}

class LeadAssignment {
  final String id;
  final String countyId;
  final String assignedById;
  final String assignedToId;
  final int leadCount;
  final DateTime timestamp;

  LeadAssignment({
    String? id,
    required this.countyId,
    required this.assignedById,
    required this.assignedToId,
    required this.leadCount,
    DateTime? timestamp,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class PersonStats {
  final String userId;
  final String userName;
  int totalLeadsAssigned;
  int countiesWorked;
  final Map<String, int> leadsByState;

  PersonStats({
    required this.userId,
    required this.userName,
    this.totalLeadsAssigned = 0,
    this.countiesWorked = 0,
    Map<String, int>? leadsByState,
  }) : leadsByState = leadsByState ?? {};
}
