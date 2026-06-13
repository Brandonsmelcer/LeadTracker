import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vl_logo.dart';
import '../services/auth_service.dart';
import 'overview_screen.dart';
import 'states_screen.dart';
import 'team_screen.dart';
import 'comms_screen.dart';
import 'stats_screen.dart';
import 'csv_import_screen.dart';
import 'login_screen.dart';

class _NavItem {
  final Widget screen;
  final NavigationDestination destination;

  const _NavItem({required this.screen, required this.destination});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<_NavItem> _navItems(AppProvider provider) => [
        if (provider.canViewGlobalOverview)
          const _NavItem(
            screen: OverviewScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,
                  color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
              label: 'Overview',
            ),
          ),
        const _NavItem(
          screen: StatesScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.map_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.map, color: AppColors.accent),
            label: 'Map',
          ),
        ),
        if (provider.canAccessTeamPortal)
          const _NavItem(
            screen: TeamScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.groups, color: AppColors.accent),
              label: 'Team',
            ),
          ),
        const _NavItem(
          screen: CommsScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.forum, color: AppColors.accent),
            label: 'Comms',
          ),
        ),
        const _NavItem(
          screen: StatsScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.analytics, color: AppColors.accent),
            label: 'Stats',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = _navItems(provider);
        final safeIndex = _currentIndex.clamp(0, items.length - 1);

        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: const VlBrandingRow(logoHeight: 28),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: AppColors.gold),
                onPressed: () => _showProfileDialog(context),
              ),
            ],
          ),
          drawer: _buildDrawer(context, provider, items, safeIndex),
          body: items[safeIndex].screen,
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: AppColors.primary,
            indicatorColor: AppColors.accent.withAlpha(60),
            destinations: items.map((i) => i.destination).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AppProvider provider,
    List<_NavItem> items,
    int currentIndex,
  ) {
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
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: VlBrandingRow(logoHeight: 28),
            ),
          ),
          if (provider.canAccessAdminPortal)
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: AppColors.gold),
              title: const Text('Admin Management',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final teamIndex = items.indexWhere(
                    (i) => i.screen is TeamScreen);
                if (teamIndex >= 0) {
                  setState(() => _currentIndex = teamIndex);
                }
              },
            ),
          if (provider.canEditMap)
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.gold),
              title: const Text('Import CSV',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CsvImportScreen()));
              },
            ),
          ListTile(
            leading:
                const Icon(Icons.download, color: AppColors.textSecondary),
            title: const Text('Export Data',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showExportSnackbar(context);
            },
          ),
          const Divider(color: AppColors.countyBorder),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value.destination.label;
            final icon = _drawerIconForLabel(label);
            return ListTile(
              leading: Icon(
                icon,
                color: index == currentIndex
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              title: Text(label, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = index);
              },
            );
          }),
          const Divider(color: AppColors.countyBorder),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.textSecondary),
            title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final auth = context.read<AuthService>();
              final app = context.read<AppProvider>();
              await auth.signOut();
              app.clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(provider.currentUser.role.name.toUpperCase(),
                style:
                    const TextStyle(color: AppColors.gold, letterSpacing: 1)),
            if (provider.currentUser.email != null) ...[
              const SizedBox(height: 4),
              Text(provider.currentUser.email!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
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

  IconData _drawerIconForLabel(String label) => switch (label) {
        'Overview' => Icons.dashboard,
        'Map' => Icons.map,
        'Team' => Icons.groups,
        'Comms' => Icons.forum,
        'Stats' => Icons.analytics,
        _ => Icons.circle,
      };
}
