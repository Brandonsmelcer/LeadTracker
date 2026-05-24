import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { master, manager, associate }

class AppUser {
  final String id;
  String name;
  UserRole role;
  String? managerId;
  String? avatarColor;
  String? homeState;
  String? homeCounty;

  AppUser({
    String? id,
    required this.name,
    required this.role,
    this.managerId,
    this.avatarColor,
    this.homeState,
    this.homeCounty,
  }) : id = id ?? _uuid.v4();

  String get homeLocation {
    if (homeCounty != null && homeState != null) {
      return '$homeCounty, $homeState';
    }
    if (homeState != null) return homeState!;
    return '';
  }

  int get totalLeads => 0;
}

class County {
  final String name;
  final String stateCode;
  int leadCount;
  String? assignedTo;
  String? sentToManager;

  County({
    required this.name,
    required this.stateCode,
    this.leadCount = 0,
    this.assignedTo,
    this.sentToManager,
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

class SaleRecord {
  final String id;
  final String associateId;
  final String managerId;
  final double amount;
  final String description;
  final DateTime timestamp;

  SaleRecord({
    String? id,
    required this.associateId,
    required this.managerId,
    required this.amount,
    this.description = '',
    DateTime? timestamp,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class PersonStats {
  final String userId;
  final String userName;
  final UserRole role;
  int totalLeadsAssigned;
  int countiesWorked;
  final Map<String, int> leadsByState;
  double totalSales;
  int salesCount;

  PersonStats({
    required this.userId,
    required this.userName,
    this.role = UserRole.associate,
    this.totalLeadsAssigned = 0,
    this.countiesWorked = 0,
    Map<String, int>? leadsByState,
    this.totalSales = 0,
    this.salesCount = 0,
  }) : leadsByState = leadsByState ?? {};
}
