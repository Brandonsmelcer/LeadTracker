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
  TabController? _tabController;
  bool _isMaster = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AppProvider>();
    final isMaster = provider.currentUser.role == UserRole.master;
    if (_tabController == null || _isMaster != isMaster) {
      _isMaster = isMaster;
      _tabController?.dispose();
      _tabController = TabController(
          length: isMaster ? 3 : 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isMaster = provider.currentUser.role == UserRole.master;
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
                  if (isMaster)
                    Tab(
                      icon: const Icon(Icons.admin_panel_settings, size: 20),
                      child: const Text('Admin'),
                    ),
                  Tab(
                    icon: const Icon(Icons.supervisor_account, size: 20),
                    child: Text('Managers (${provider.managers.length})'),
                  ),
                  Tab(
                    icon: const Icon(Icons.person, size: 20),
                    child: Text('Team (${provider.associates.length})'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  if (isMaster) _MasterTab(provider: provider),
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
    final homeStateCtrl = TextEditingController();
    final homeCountyCtrl = TextEditingController();
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Add Associate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: homeStateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Home State', hintText: 'e.g. TN'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: homeCountyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Home County', hintText: 'e.g. Davidson'),
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
                      managerId: selectedManagerId,
                      homeState: homeStateCtrl.text.trim().isEmpty
                          ? null : homeStateCtrl.text.trim(),
                      homeCounty: homeCountyCtrl.text.trim().isEmpty
                          ? null : homeCountyCtrl.text.trim());
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
    final homeInfo = user.homeLocation;
    final isMaster = provider.currentUser.role == UserRole.master;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(user.name[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(user.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
          if (homeInfo.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.home, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(homeInfo,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
        ],
      ),
      trailing: user.role != UserRole.master
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMaster)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
                    onPressed: () => _showEditDialog(context),
                    tooltip: 'Edit',
                  ),
                if (isMaster)
                  IconButton(
                    icon: const Icon(Icons.person_remove, color: AppColors.accent, size: 20),
                    onPressed: () => _confirmRemove(context),
                    tooltip: 'Remove',
                  ),
              ],
            )
          : null,
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Remove User'),
        content: Text('Remove ${user.name} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeUser(user.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final homeStateCtrl = TextEditingController(text: user.homeState ?? '');
    final homeCountyCtrl = TextEditingController(text: user.homeCounty ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Edit ${user.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeStateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Home State',
                  hintText: 'e.g. TN',
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: homeCountyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Home County',
                  hintText: 'e.g. Davidson',
                ),
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
              provider.updateUser(user.id,
                  homeState: homeStateCtrl.text.trim().isEmpty
                      ? null : homeStateCtrl.text.trim(),
                  homeCounty: homeCountyCtrl.text.trim().isEmpty
                      ? null : homeCountyCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
