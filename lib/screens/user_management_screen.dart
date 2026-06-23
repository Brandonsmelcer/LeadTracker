import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Set<String> _updating = {};

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

    print('[UserManagement] updating role for ${user.email} (${user.uid}) '
        'from ${user.role.name} to ${newRole.name}');

    try {
      await auth.updateUserRole(
        callerRole: app.currentUser.role,
        uid: user.uid,
        role: newRole,
      );
      print('[UserManagement] Firestore role update succeeded for ${user.uid}');
      if (!mounted) return;
      setState(() => _updating.remove(user.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${user.email} to ${newRole.name}.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, stack) {
      print('[UserManagement] role update FAILED for ${user.uid} -> ${newRole.name}');
      print('[UserManagement] error: $e');
      if (e is FirebaseException) {
        print('[UserManagement] FirebaseException.code: ${e.code}');
        print('[UserManagement] FirebaseException.message: ${e.message}');
      }
      print('[UserManagement] stackTrace: $stack');
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

        final auth = context.read<AuthService>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
          ),
          body: StreamBuilder<List<UserProfile>>(
            stream: auth.watchAllUsers(app.currentUser.role),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'No users found in Firestore.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.separated(
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
                        border: Border.all(
                            color: AppColors.countyBorder.withAlpha(80)),
                      ),
                      child: const Text(
                        'Manage roles for all registered users. Changes sync live from Firestore.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    );
                  }

                  final user = users[index - 1];
                  return _UserRoleTile(
                    user: user,
                    app: app,
                    isUpdating: _updating.contains(user.uid),
                    onRoleChanged: (role) => _changeRole(user, role),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _UserRoleTile extends StatelessWidget {
  final UserProfile user;
  final AppProvider app;
  final bool isUpdating;
  final ValueChanged<UserRole> onRoleChanged;

  const _UserRoleTile({
    required this.user,
    required this.app,
    required this.isUpdating,
    required this.onRoleChanged,
  });

  String get _roleStatusLabel {
    if (!user.approved) return '${user.role.name} • pending approval';
    return user.role.name;
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = user.uid == app.currentUser.id;

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
          '${user.name}${isSelf ? ' • You' : ''} • Role: $_roleStatusLabel',
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
                child: DropdownButton<UserRole>(
                  isExpanded: true,
                  value: user.role,
                  dropdownColor: AppColors.surface,
                  underline: Container(
                    height: 1,
                    color: AppColors.countyBorder.withAlpha(120),
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
                    if (role == null || role == user.role) return;
                    print(
                      '[UserManagement] dropdown onChanged: ${user.email} '
                      '(${user.uid}) selected ${role.name}',
                    );
                    try {
                      onRoleChanged(role);
                    } catch (e, stack) {
                      print(
                        '[UserManagement] synchronous error in onChanged: $e',
                      );
                      print('[UserManagement] stackTrace: $stack');
                    }
                  },
                ),
              ),
      ),
    );
  }
}
