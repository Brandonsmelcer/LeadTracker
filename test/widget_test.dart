import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lead_tracker/providers/app_provider.dart';
import 'package:lead_tracker/models/models.dart';
import 'package:lead_tracker/screens/home_screen.dart';
import 'package:lead_tracker/widgets/vl_logo.dart';

void main() {
  group('AppProvider', () {
    late AppProvider provider;

    setUp(() {
      provider = AppProvider.testing();
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

    test('starts with admin user', () {
      expect(provider.currentUser.role, UserRole.admin);
      expect(provider.users.length, 1);
      expect(provider.canEditMap, isTrue);
      expect(provider.canAccessMap, isTrue);
      expect(provider.canViewGlobalOverview, isTrue);
    });

    test('manager and associate cannot access map', () {
      provider.applyLocalDebugSession(
        role: UserRole.manager,
        email: AuthEmails.manager,
        uid: 'debug-manager',
        name: 'Manager Tester',
      );
      expect(provider.canAccessMap, isFalse);

      provider.applyLocalDebugSession(
        role: UserRole.associate,
        email: AuthEmails.associate,
        uid: 'debug-associate',
        name: 'Associate Tester',
      );
      expect(provider.canAccessMap, isFalse);
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

    test('record lead outcome marks sale with revenue', () async {
      provider.addUser('Agent 1', UserRole.associate);
      final agentId = provider.associates.first.id;
      provider.updateCountyLeads('TN', 'Davidson', 5);
      provider.assignCounty('TN', 'Davidson', agentId);

      final error = await provider.recordLeadOutcome(
        associateId: agentId,
        stateCode: 'TN',
        countyName: 'Davidson',
        disposition: LeadStatus.sold,
        saleAmount: 12500,
        closingNotes: 'Closed same day',
      );

      expect(error, isNull);
      final tn = provider.states.firstWhere((s) => s.code == 'TN');
      final davidson = tn.counties.firstWhere((c) => c.name == 'Davidson');
      expect(davidson.assignedTo, agentId);
      expect(davidson.leadCount, 4);
      expect(provider.leads.length, 1);
      expect(provider.leads.first.status, LeadStatus.sold);
      expect(provider.leads.first.saleAmount, 12500);
      expect(provider.totalRevenue, 12500);
      expect(provider.totalSalesCount, 1);

      final stats = provider.getStats();
      final agentStat = stats.firstWhere((s) => s.userId == agentId);
      expect(agentStat.totalSalesCount, 1);
      expect(agentStat.totalRevenue, 12500);
    });

    test('undecided outcome keeps lead in active pipeline', () async {
      provider.addUser('Agent 1', UserRole.associate);
      final agentId = provider.associates.first.id;
      provider.updateCountyLeads('TN', 'Davidson', 3);
      provider.assignCounty('TN', 'Davidson', agentId);

      final error = await provider.recordLeadOutcome(
        associateId: agentId,
        stateCode: 'TN',
        countyName: 'Davidson',
        disposition: LeadStatus.undecided,
        closingNotes: 'Call back Friday',
      );

      expect(error, isNull);
      final davidson = provider.states
          .firstWhere((s) => s.code == 'TN')
          .counties
          .firstWhere((c) => c.name == 'Davidson');
      expect(davidson.leadCount, 3);
      expect(provider.leads.first.status, LeadStatus.undecided);

      final agentStat =
          provider.getStats().firstWhere((s) => s.userId == agentId);
      expect(agentStat.undecidedCount, 1);
    });

    test('not interested outcome archives lead from pipeline', () async {
      provider.addUser('Agent 1', UserRole.associate);
      final agentId = provider.associates.first.id;
      provider.updateCountyLeads('TN', 'Davidson', 2);
      provider.assignCounty('TN', 'Davidson', agentId);

      await provider.recordLeadOutcome(
        associateId: agentId,
        stateCode: 'TN',
        countyName: 'Davidson',
        disposition: LeadStatus.notInterested,
        closingNotes: 'No budget',
      );

      final davidson = provider.states
          .firstWhere((s) => s.code == 'TN')
          .counties
          .firstWhere((c) => c.name == 'Davidson');
      expect(davidson.leadCount, 1);
      expect(provider.leads.first.status, LeadStatus.notInterested);
    });

    test('manual lead on empty county adds active lead and map pin', () async {
      provider.addUser('Agent 1', UserRole.associate);
      final agentId = provider.associates.first.id;

      final error = await provider.addManualLead(
        stateCode: 'TN',
        countyName: 'Davidson',
        contactName: 'Jane Doe',
        phone: '615-555-0100',
        address: '123 Main St, Nashville',
        assignedToId: agentId,
      );

      expect(error, isNull);
      expect(provider.leads.length, 1);
      expect(provider.leads.first.status, LeadStatus.active);
      expect(provider.leads.first.contactName, 'Jane Doe');
      expect(provider.leads.first.phone, '615-555-0100');

      final davidson = provider.states
          .firstWhere((s) => s.code == 'TN')
          .counties
          .firstWhere((c) => c.name == 'Davidson');
      expect(davidson.leadCount, 1);
      expect(davidson.assignedTo, agentId);
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

  group('Widget Tests', () {
    testWidgets('App renders and shows logo branding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider.testing(),
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == kAppLogoAsset,
        ),
        findsWidgets,
      );
      expect(find.text('Map'), findsWidgets);
    });

    testWidgets('manager nav hides map tab', (WidgetTester tester) async {
      final provider = AppProvider();
      provider.applyLocalDebugSession(
        role: UserRole.manager,
        email: AuthEmails.manager,
        uid: 'debug-manager',
        name: 'Manager Tester',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Map'), findsNothing);
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Stats'), findsWidgets);
    });
  });
}
