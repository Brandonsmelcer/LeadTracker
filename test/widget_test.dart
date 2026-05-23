import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/providers/app_provider.dart';
import 'package:lead_tracker/models/models.dart';

void main() {
  group('AppProvider', () {
    late AppProvider provider;

    setUp(() {
      provider = AppProvider();
    });

    test('initializes with 3 states (TN, KY, WV)', () {
      expect(provider.states.length, 3);
      expect(provider.states.map((s) => s.code).toList(),
          containsAll(['TN', 'KY', 'WV']));
    });

    test('TN has 95 counties', () {
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      expect(tn.counties.length, 95);
    });

    test('KY has 120 counties', () {
      final ky = provider.states.firstWhere((s) => s.code == 'KY');
      expect(ky.counties.length, 120);
    });

    test('WV has 55 counties', () {
      final wv = provider.states.firstWhere((s) => s.code == 'WV');
      expect(wv.counties.length, 55);
    });

    test('starts with master user', () {
      expect(provider.currentUser.role, UserRole.master);
      expect(provider.users.length, 1);
    });

    test('can add manager', () {
      provider.addUser('Test Manager', UserRole.manager);
      expect(provider.managers.length, 1);
      expect(provider.managers.first.name, 'Test Manager');
    });

    test('can add associate under manager', () {
      provider.addUser('Test Manager', UserRole.manager);
      final managerId = provider.managers.first.id;
      provider.addUser('Test Associate', UserRole.associate,
          managerId: managerId);
      expect(provider.associates.length, 1);
      expect(provider.associates.first.managerId, managerId);
    });

    test('can update county leads', () {
      provider.updateCountyLeads('TN', 'Davidson', 42);
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.leadCount, 42);
      expect(tn.totalLeads, 42);
    });

    test('can assign county to user', () {
      provider.addUser('Agent 1', UserRole.associate);
      final userId = provider.associates.first.id;
      provider.assignCounty('TN', 'Davidson', userId);
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.assignedTo, userId);
    });

    test('can import CSV data', () {
      final csv = 'State,County,Leads,Assignee\nTN,Davidson,50,\nKY,Jefferson,30,\n';
      final result = provider.importCsv(csv);
      expect(result, contains('Imported'));
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.leadCount, greaterThan(0));
    });

    test('starts with 4 chat channels', () {
      expect(provider.channels.length, 4);
    });

    test('can add message to channel', () {
      final channelId = provider.channels.first.id;
      provider.addNote('Hello team!', channelId: channelId);
      expect(provider.channels.first.messages.length, 1);
      expect(provider.channels.first.messages.first.content, 'Hello team!');
    });

    test('can add new channel', () {
      provider.addChannel('test-channel');
      expect(provider.channels.length, 5);
    });

    test('stats track assigned leads per person', () {
      provider.addUser('Agent 1', UserRole.associate);
      final userId = provider.associates.first.id;
      provider.updateCountyLeads('TN', 'Davidson', 25);
      provider.assignCounty('TN', 'Davidson', userId);
      final stats = provider.getStats();
      final agentStat = stats.firstWhere((s) => s.userId == userId);
      expect(agentStat.totalLeadsAssigned, 25);
      expect(agentStat.countiesWorked, 1);
    });

    test('delegate leads works', () {
      provider.addUser('Manager 1', UserRole.manager);
      provider.addUser('Agent 1', UserRole.associate);
      final managerId = provider.managers.first.id;
      final agentId = provider.associates.first.id;
      provider.delegateLeads(managerId, agentId, 'TN', 'Davidson', 100);
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.assignedTo, agentId);
      expect(davidson.leadCount, 100);
    });

    test('removing user clears assignments', () {
      provider.addUser('Agent 1', UserRole.associate);
      final userId = provider.associates.first.id;
      provider.assignCounty('TN', 'Davidson', userId);
      provider.removeUser(userId);
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.assignedTo, isNull);
    });
  });

  group('Sales', () {
    test('can record a sale', () {
      final provider = AppProvider();
      provider.addUser('Manager 1', UserRole.manager);
      provider.addUser('Agent 1', UserRole.associate);
      final managerId = provider.managers.first.id;
      final agentId = provider.associates.first.id;
      provider.recordSale(agentId, managerId, 5000, description: 'Test sale');
      expect(provider.sales.length, 1);
      expect(provider.totalRevenue, 5000);
      expect(provider.getTeamRevenue(managerId), 5000);
      expect(provider.getPersonRevenue(agentId), 5000);
    });

    test('stats include sales data', () {
      final provider = AppProvider();
      provider.addUser('Manager 1', UserRole.manager);
      provider.addUser('Agent 1', UserRole.associate);
      final managerId = provider.managers.first.id;
      final agentId = provider.associates.first.id;
      provider.recordSale(agentId, managerId, 3000);
      provider.recordSale(agentId, managerId, 2000);
      final stats = provider.getStats();
      final agentStat = stats.firstWhere((s) => s.userId == agentId);
      expect(agentStat.totalSales, 5000);
      expect(agentStat.salesCount, 2);
    });
  });
}
