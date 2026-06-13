import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CountyDetailDialog {
  static void show(
    BuildContext context, {
    required County county,
    required String stateCode,
    required AppProvider provider,
  }) {
    if (!provider.canEditMap) {
      _showReadOnly(context, county: county, stateCode: stateCode, provider: provider);
      return;
    }

    final leadController = TextEditingController(
        text: county.leadCount > 0 ? county.leadCount.toString() : '');
    String? selectedUserId = county.assignedTo;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(county.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('State: $stateCode',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: leadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lead Count',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Assign To:',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned',
                            style:
                                TextStyle(color: AppColors.textSecondary))),
                    ...provider.users.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.role.name})',
                              style: const TextStyle(color: Colors.white)),
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
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
                final count = int.tryParse(leadController.text) ?? 0;
                provider.updateCountyLeads(stateCode, county.name, count);
                provider.assignCounty(stateCode, county.name, selectedUserId);
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showReadOnly(
    BuildContext context, {
    required County county,
    required String stateCode,
    required AppProvider provider,
  }) {
    final assignee = county.assignedTo != null
        ? provider.users.cast<AppUser?>().firstWhere(
            (u) => u!.id == county.assignedTo,
            orElse: () => null)
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(county.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: $stateCode',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Leads: ${county.leadCount}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Assigned: ${assignee?.name ?? 'Unassigned'}',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
