import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'overview_screen.dart';
import 'states_screen.dart';
import 'team_screen.dart';
import 'comms_screen.dart';
import 'stats_screen.dart';
import 'csv_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    OverviewScreen(),
    StatesScreen(),
    TeamScreen(),
    CommsScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(Icons.visibility, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VISION TO LEGACY',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                Text('Lead Tracker',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                        letterSpacing: 1)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.gold),
            onPressed: () => _showProfileDialog(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent.withAlpha(60),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.map, color: AppColors.accent),
            label: 'States',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.groups, color: AppColors.accent),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.forum, color: AppColors.accent),
            label: 'Comms',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.analytics, color: AppColors.accent),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.visibility, color: AppColors.gold, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('VISION TO LEGACY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const Text('Lead Tracker Pro',
                    style: TextStyle(color: AppColors.gold, fontSize: 13)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: AppColors.gold),
            title: const Text('Import CSV', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CsvImportScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: AppColors.textSecondary),
            title: const Text('Export Data', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showExportSnackbar(context);
            },
          ),
          const Divider(color: AppColors.countyBorder),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.textSecondary),
            title: const Text('Overview', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map, color: AppColors.textSecondary),
            title: const Text('States & Counties', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups, color: AppColors.textSecondary),
            title: const Text('Team Management', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum, color: AppColors.textSecondary),
            title: const Text('Communications', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: AppColors.textSecondary),
            title: const Text('Statistics', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          const Divider(color: AppColors.countyBorder),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('v1.0.0 • Vision To Legacy Group',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent,
              child: Text(provider.currentUser.name[0],
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(provider.currentUser.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(provider.currentUser.role.name.toUpperCase(),
                style: const TextStyle(color: AppColors.gold, letterSpacing: 1)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
