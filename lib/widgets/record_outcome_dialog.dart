import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Shared sales / lead outcome form used from Stats and the map cold-call flow.
class RecordOutcomeDialog {
  RecordOutcomeDialog._();

  static Future<void> show(
    BuildContext context, {
    required AppProvider provider,
    String? initialStateCode,
    String? initialCountyName,
    String? initialAssociateId,
    LeadStatus? initialDisposition,
  }) {
    final saleAmountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedStateCode = initialStateCode;
    String? selectedCountyName = initialCountyName;
    String? selectedAssociateId = initialAssociateId ??
        (provider.currentUser.role == UserRole.associate
            ? provider.currentUser.id
            : null);
    LeadStatus? selectedDisposition = initialDisposition;
    String? errorMessage;
    bool submitting = false;

    final availableAssociates = provider.visibleAssociates;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final canSubmit = !submitting &&
              selectedStateCode != null &&
              selectedCountyName != null &&
              selectedAssociateId != null &&
              selectedDisposition != null &&
              (selectedDisposition != LeadStatus.sold ||
                  (double.tryParse(saleAmountCtrl.text) ?? 0) > 0);

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Text('Record Lead Outcome'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStateCode,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: provider.states
                        .map((s) => DropdownMenuItem(
                            value: s.code, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setD(() {
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
                              value: c.name,
                              child: Text(
                                  '${c.name} (${c.leadCount} active)')))
                          .toList(),
                      onChanged: (v) => setD(() => selectedCountyName = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: availableAssociates
                            .any((u) => u.id == selectedAssociateId)
                        ? selectedAssociateId
                        : null,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'Associate'),
                    items: availableAssociates
                        .map((u) => DropdownMenuItem(
                            value: u.id, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) => setD(() => selectedAssociateId = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Disposition',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  _dispositionOption(
                    setD: setD,
                    disposition: LeadStatus.sold,
                    selected: selectedDisposition,
                    icon: Icons.check_circle,
                    color: AppColors.gold,
                    title: 'Sold',
                    subtitle: 'Record revenue and close the lead',
                    onSelect: () {
                      selectedDisposition = LeadStatus.sold;
                      notesCtrl.clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  _dispositionOption(
                    setD: setD,
                    disposition: LeadStatus.undecided,
                    selected: selectedDisposition,
                    icon: Icons.schedule,
                    color: AppColors.accent,
                    title: 'Undecided',
                    subtitle: 'Keep in follow-up rotation',
                    onSelect: () {
                      selectedDisposition = LeadStatus.undecided;
                      saleAmountCtrl.clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  _dispositionOption(
                    setD: setD,
                    disposition: LeadStatus.notInterested,
                    selected: selectedDisposition,
                    icon: Icons.block,
                    color: AppColors.textSecondary,
                    title: 'Not Interested',
                    subtitle: 'Archive from active dashboards',
                    onSelect: () {
                      selectedDisposition = LeadStatus.notInterested;
                      saleAmountCtrl.clear();
                    },
                  ),
                  if (selectedDisposition == LeadStatus.sold) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: saleAmountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sale Amount (\$)',
                        prefixText: '\$ ',
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setD(() {}),
                    ),
                  ],
                  if (selectedDisposition == LeadStatus.undecided) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Follow-up Notes (optional)',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  if (selectedDisposition == LeadStatus.notInterested) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Notes (optional)',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!,
                        style: const TextStyle(color: Colors.redAccent)),
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
                        final error = await provider.recordLeadOutcome(
                          associateId: selectedAssociateId!,
                          stateCode: selectedStateCode!,
                          countyName: selectedCountyName!,
                          disposition: selectedDisposition!,
                          saleAmount: selectedDisposition == LeadStatus.sold
                              ? double.tryParse(saleAmountCtrl.text)
                              : null,
                          closingNotes: notesCtrl.text,
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
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _dispositionOption({
    required void Function(void Function()) setD,
    required LeadStatus disposition,
    required LeadStatus? selected,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onSelect,
  }) {
    final isSelected = selected == disposition;
    return InkWell(
      onTap: () => setD(onSelect),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.countyBorder.withAlpha(80),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.white)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.radio_button_checked, color: color),
          ],
        ),
      ),
    );
  }
}
