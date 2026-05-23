import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Container(
              color: AppColors.primary,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.admin_panel_settings, size: 20),
                    child: Text('Master (${provider.users.where((u) => u.role == UserRole.master).length})'),
                  ),
                  Tab(
                    icon: const Icon(Icons.supervisor_account, size: 20),
                    child: Text('Managers (${provider.managers.length})'),
                  ),
                  Tab(
                    icon: const Icon(Icons.person, size: 20),
                    child: Text('Associates (${provider.associates.length})'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MasterTab(provider: provider),
                  _ManagersTab(provider: provider),
                  _AssociatesTab(provider: provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MasterTab extends StatelessWidget {
  final AppProvider provider;
  const _MasterTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final masters = provider.users.where((u) => u.role == UserRole.master).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withAlpha(100)),
          ),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: AppColors.gold, size: 48),
              const SizedBox(height: 12),
              const Text('MASTER CONTROL',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Full access to all teams, leads, and delegation',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickStat('Managers', '${provider.managers.length}'),
                  _quickStat('Associates', '${provider.associates.length}'),
                  _quickStat('Total Leads', '${provider.totalLeads}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...masters.map((m) => _UserCard(user: m, provider: provider)),
        const SizedBox(height: 24),
        const Text('QUICK ACTIONS',
            style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _actionTile(context, Icons.person_add, 'Add Manager', () {
          _showAddUserDialog(context, UserRole.manager);
        }),
        _actionTile(context, Icons.person_add_alt, 'Add Associate', () {
          _showAddUserDialog(context, UserRole.associate);
        }),
        _actionTile(context, Icons.assignment_ind, 'Delegate Leads', () {
          _showDelegateDialog(context);
        }),
      ],
    );
  }

  Widget _quickStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _actionTile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: AppColors.accent),
        title: Text(label),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserRole role) {
    final nameCtrl = TextEditingController();
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text('Add ${role.name.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                style: const TextStyle(color: Colors.white),
              ),
              if (role == UserRole.associate && provider.managers.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedManagerId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign to Manager'),
                  items: provider.managers
                      .map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedManagerId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  provider.addUser(nameCtrl.text.trim(), role,
                      managerId: selectedManagerId);
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDelegateDialog(BuildContext context) {
    String? selectedStateCode;
    String? selectedCountyName;
    String? selectedUserId;
    final leadsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Delegate Leads'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedStateCode,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: provider.states
                      .map((s) => DropdownMenuItem(
                          value: s.code, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedStateCode = v;
                    selectedCountyName = null;
                  }),
                ),
                if (selectedStateCode != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCountyName,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'County'),
                    items: provider.states
                        .firstWhere((s) => s.code == selectedStateCode)
                        .counties
                        .map((c) => DropdownMenuItem(
                            value: c.name, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCountyName = v),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: provider.users
                      .where((u) => u.role != UserRole.master)
                      .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.role.name})')))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedUserId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: leadsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lead Count'),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedStateCode != null &&
                    selectedCountyName != null &&
                    selectedUserId != null) {
                  final count = int.tryParse(leadsCtrl.text) ?? 0;
                  provider.delegateLeads(
                    provider.currentUser.id,
                    selectedUserId!,
                    selectedStateCode!,
                    selectedCountyName!,
                    count,
                  );
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Delegate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagersTab extends StatelessWidget {
  final AppProvider provider;
  const _ManagersTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final managers = provider.managers;

    if (managers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.supervisor_account,
                size: 64, color: AppColors.countyBorder),
            const SizedBox(height: 16),
            const Text('No managers yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showAddManagerDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Manager'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...managers.map((m) {
          final team = provider.getTeamFor(m.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
            ),
            child: Column(
              children: [
                _UserCard(user: m, provider: provider),
                if (team.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Team Members:',
                            style: TextStyle(
                                color: AppColors.gold, fontSize: 12)),
                        const SizedBox(height: 4),
                        ...team.map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(t.name,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: () => _showAddManagerDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Manager'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          ),
        ),
      ],
    );
  }

  void _showAddManagerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Add Manager'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addUser(nameCtrl.text.trim(), UserRole.manager);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AssociatesTab extends StatelessWidget {
  final AppProvider provider;
  const _AssociatesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final associates = provider.associates;

    if (associates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline,
                size: 64, color: AppColors.countyBorder),
            const SizedBox(height: 16),
            const Text('No associates yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showAddAssociateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Associate'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...associates.map((a) {
          final manager = a.managerId != null
              ? provider.users.cast<AppUser?>().firstWhere(
                  (u) => u!.id == a.managerId,
                  orElse: () => null)
              : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: _UserCard(
              user: a,
              provider: provider,
              subtitle: manager != null ? 'Manager: ${manager.name}' : 'Unassigned',
            ),
          );
        }),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: () => _showAddAssociateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Associate'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          ),
        ),
      ],
    );
  }

  void _showAddAssociateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Add Associate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                style: const TextStyle(color: Colors.white),
              ),
              if (provider.managers.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedManagerId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign to Manager'),
                  items: provider.managers
                      .map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedManagerId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  provider.addUser(nameCtrl.text.trim(), UserRole.associate,
                      managerId: selectedManagerId);
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final AppProvider provider;
  final String? subtitle;

  const _UserCard({required this.user, required this.provider, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(user.avatarColor ?? '#E94560');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(user.name[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(user.name),
      subtitle: Text(subtitle ?? user.role.name.toUpperCase(),
          style: const TextStyle(color: AppColors.gold, fontSize: 12)),
      trailing: user.role != UserRole.master
          ? IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: () => _showUserOptions(context),
            )
          : null,
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _showUserOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.accent),
              title: const Text('Remove User'),
              onTap: () {
                provider.removeUser(user.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
