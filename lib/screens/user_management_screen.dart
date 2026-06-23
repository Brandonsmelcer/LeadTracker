import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserProfile>? _users;
  String? _error;
  bool _loading = true;
  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final app = context.read<AppProvider>();
    final auth = context.read<AuthService>();

    try {
      final users = await auth.fetchAllUsers(app.currentUser.role);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(UserProfile user, UserRole newRole) async {
    if (user.role == newRole) return;

    final app = context.read<AppProvider>();
    final auth = context.read<AuthService>();

    if (user.uid == app.currentUser.id && newRole != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot remove your own admin access.'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    setState(() => _updating.add(user.uid));

    try {
      await auth.updateUserRole(
        callerRole: app.currentUser.role,
        uid: user.uid,
        role: newRole,
      );
      if (!mounted) return;
      setState(() {
        _users = _users
            ?.map((u) => u.uid == user.uid
                ? UserProfile(
                    uid: u.uid,
                    email: u.email,
                    name: u.name,
                    role: newRole,
                    managerId: u.managerId,
                    approved: u.approved,
                  )
                : u)
            .toList();
        _updating.remove(user.uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${user.email} to ${newRole.name}.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating.remove(user.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (!app.canAccessAdminPortal) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Management')),
            body: const Center(
              child: Text(
                'Administrator access required.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loading ? null : _loadUsers,
              ),
            ],
          ),
          body: _buildBody(app),
        );
      },
    );
  }

  Widget _buildBody(AppProvider app) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadUsers,
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final users = _users ?? [];
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found in Firestore.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
              ),
              child: const Text(
                'Manage roles for all registered users. Changes are saved to Firestore immediately.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            );
          }

          final user = users[index - 1];
          final isSelf = user.uid == app.currentUser.id;
          final isUpdating = _updating.contains(user.uid);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelf
                    ? AppColors.gold.withAlpha(100)
                    : AppColors.countyBorder.withAlpha(80),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${user.name}${isSelf ? ' • You' : ''}${user.approved ? '' : ' • Pending approval'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: isUpdating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<UserRole>(
                        initialValue: user.role,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: UserRole.values
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (role) {
                          if (role != null) _changeRole(user, role);
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
