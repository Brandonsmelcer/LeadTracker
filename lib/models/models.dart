import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { admin, manager, associate, pending }

UserRole? userRoleFromFirestore(String? value) {
  switch (value?.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'associate':
      return UserRole.associate;
    case 'pending':
      return UserRole.pending;
    default:
      return null;
  }
}

extension UserRolePermissions on UserRole {
  bool get canEditMap => this == UserRole.admin;
  bool get canAccessMap => this == UserRole.admin;
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
  final LeadStatus? disposition;
  final double? saleAmount;
  final String? closingNotes;

  LeadAssignment({
    String? id,
    required this.countyId,
    required this.assignedById,
    required this.assignedToId,
    required this.leadCount,
    DateTime? timestamp,
    this.disposition,
    this.saleAmount,
    this.closingNotes,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

enum LeadStatus { active, sold, undecided, notInterested }

LeadStatus? leadStatusFromFirestore(String? value) {
  switch (value) {
    case 'active':
      return LeadStatus.active;
    case 'sold':
      return LeadStatus.sold;
    case 'undecided':
      return LeadStatus.undecided;
    case 'not_interested':
      return LeadStatus.notInterested;
    default:
      return null;
  }
}

extension LeadStatusSerialization on LeadStatus {
  String get firestoreValue => switch (this) {
        LeadStatus.active => 'active',
        LeadStatus.sold => 'sold',
        LeadStatus.undecided => 'undecided',
        LeadStatus.notInterested => 'not_interested',
      };

  String get label => switch (this) {
        LeadStatus.active => 'Active',
        LeadStatus.sold => 'Sold',
        LeadStatus.undecided => 'Undecided',
        LeadStatus.notInterested => 'Not Interested',
      };

  bool get countsInActivePipeline =>
      this == LeadStatus.active || this == LeadStatus.undecided;
}

class Lead {
  final String id;
  final String countyId;
  final String stateCode;
  final String countyName;
  final String assignedToId;
  final String recordedById;
  LeadStatus status;
  double? saleAmount;
  String? closingNotes;
  String? contactName;
  String? phone;
  String? address;
  final DateTime createdAt;
  DateTime updatedAt;

  Lead({
    String? id,
    required this.countyId,
    required this.stateCode,
    required this.countyName,
    required this.assignedToId,
    required this.recordedById,
    this.status = LeadStatus.active,
    this.saleAmount,
    this.closingNotes,
    this.contactName,
    this.phone,
    this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Lead.fromMap(String id, Map<String, dynamic> data) {
    return Lead(
      id: id,
      countyId: data['countyId'] as String? ?? '',
      stateCode: data['stateCode'] as String? ?? '',
      countyName: data['countyName'] as String? ?? '',
      assignedToId: data['assignedToId'] as String? ?? '',
      recordedById: data['recordedById'] as String? ?? '',
      status: leadStatusFromFirestore(data['status'] as String?) ??
          LeadStatus.active,
      saleAmount: (data['saleAmount'] as num?)?.toDouble(),
      closingNotes: data['closingNotes'] as String?,
      contactName: data['contactName'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      createdAt: _timestampFromData(data['createdAt']),
      updatedAt: _timestampFromData(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'countyId': countyId,
        'stateCode': stateCode,
        'countyName': countyName,
        'assignedToId': assignedToId,
        'recordedById': recordedById,
        'status': status.firestoreValue,
        'saleAmount': saleAmount,
        'closingNotes': closingNotes,
        'contactName': contactName,
        'phone': phone,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

DateTime _timestampFromData(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class PersonStats {
  final String userId;
  final String userName;
  int totalLeadsAssigned;
  int countiesWorked;
  int totalSalesCount;
  double totalRevenue;
  int undecidedCount;
  final Map<String, int> leadsByState;

  PersonStats({
    required this.userId,
    required this.userName,
    this.totalLeadsAssigned = 0,
    this.countiesWorked = 0,
    this.totalSalesCount = 0,
    this.totalRevenue = 0,
    this.undecidedCount = 0,
    Map<String, int>? leadsByState,
  }) : leadsByState = leadsByState ?? {};
}
