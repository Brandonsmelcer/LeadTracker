import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Streamlined form for adding a manual lead to an empty county.
class ManualLeadDialog {
  ManualLeadDialog._();

  static Future<void> show(
    BuildContext context, {
    required AppProvider provider,
    required String stateCode,
    required String countyName,
  }) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String? errorMessage;
    bool submitting = false;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final canSubmit = !submitting &&
              nameCtrl.text.trim().isNotEmpty &&
              phoneCtrl.text.trim().isNotEmpty &&
              addressCtrl.text.trim().isNotEmpty;

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text('Add Lead — $countyName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$stateCode • $countyName',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setD(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setD(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Address'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setD(() {}),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canSubmit
                    ? () async {
                        setD(() {
                          submitting = true;
                          errorMessage = null;
                        });
                        final error = await provider.addManualLead(
                          stateCode: stateCode,
                          countyName: countyName,
                          contactName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        if (error == null) {
                          Navigator.pop(ctx);
                        } else {
                          setD(() {
                            submitting = false;
                            errorMessage = error;
                          });
                        }
                      }
                    : null,
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Lead'),
              ),
            ],
          );
        },
      ),
    );
  }
}
