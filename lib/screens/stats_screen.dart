import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStats();
        final topAgent = stats.isNotEmpty &&
                (stats.first.totalLeadsAssigned > 0 ||
                    stats.first.totalRevenue > 0)
            ? stats.first
            : null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (topAgent != null) _buildTopAgentHero(topAgent),
              const SizedBox(height: 16),
              _buildLeadsSummaryCard(provider),
              const SizedBox(height: 16),
              _buildTeamLeadsCards(provider),
              const SizedBox(height: 16),
              _buildOverallStats(provider),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: Text('INDIVIDUAL PERFORMANCE',
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (stats.isEmpty ||
                  stats.every((s) =>
                      s.totalLeadsAssigned == 0 && s.totalRevenue == 0))
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 48, color: AppColors.countyBorder),
                      SizedBox(height: 12),
                      Text('No stats yet',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      Text('Record lead outcomes or assign counties to see statistics',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...stats.asMap().entries.map((entry) =>
                    _buildPersonCard(entry.value, entry.key + 1, provider)),
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: provider.canAddAssociates
              ? FloatingActionButton.extended(
                  onPressed: () => _showRecordOutcomeDialog(context, provider),
                  backgroundColor: AppColors.accent,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Record Outcome',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTopAgentHero(PersonStats topAgent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(100)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 40),
          const SizedBox(height: 8),
          const Text('TOP AGENT',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(topAgent.userName,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (topAgent.totalRevenue > 0) ...[
            Text('\$${_formatCurrency(topAgent.totalRevenue)}',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            Text('${topAgent.totalSalesCount} sales closed',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ] else
            Text('${topAgent.totalLeadsAssigned} active leads',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
          Text('${topAgent.countiesWorked} counties worked',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLeadsSummaryCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.accent.withAlpha(40)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Text('PIPELINE & REVENUE',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryMetric('Active Leads', '${provider.totalLeads}'),
              _summaryMetric('Sales', '${provider.totalSalesCount}'),
              _summaryMetric(
                  'Revenue', '\$${_formatCurrency(provider.totalRevenue)}'),
            ],
          ),
          const SizedBox(height: 8),
          Text('${provider.coveredCounties} of ${provider.totalCounties} counties covered',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.accent)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildTeamLeadsCards(AppProvider provider) {
    final managers = provider.currentUser.role == UserRole.admin
        ? provider.managers
        : provider.currentUser.role == UserRole.manager
            ? [provider.currentUser]
            : <AppUser>[];

    if (managers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEAM LEADS',
            style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...managers.map((m) {
          final teamLeads = provider.getTeamLeads(m.id);
          final teamMembers = provider.getTeamFor(m.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Text(m.name[0],
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${m.name}'s Team",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${teamMembers.length} associates',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('$teamLeads leads',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOverallStats(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TEAM OVERVIEW',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _overviewTile(
                      'Team', '${provider.users.length}', Icons.groups)),
              Expanded(
                  child: _overviewTile('Managers',
                      '${provider.managers.length}', Icons.supervisor_account)),
              Expanded(
                  child: _overviewTile('Associates',
                      '${provider.associates.length}', Icons.person)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _overviewTile(
                      'Leads', '${provider.totalLeads}', Icons.trending_up)),
              Expanded(
                  child: _overviewTile('Sales',
                      '${provider.totalSalesCount}', Icons.payments)),
              Expanded(
                  child: _overviewTile('Covered',
                      '${provider.coveredCounties}', Icons.check_circle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPersonCard(PersonStats stat, int rank, AppProvider provider) {
    final role = provider.roleForUser(stat.userId);
    final roleLabel = role?.name ?? 'unknown';
    final hasActivity =
        stat.totalLeadsAssigned > 0 || stat.totalRevenue > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: rank == 1 && hasActivity
            ? Border.all(color: AppColors.gold.withAlpha(100))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 && hasActivity
                  ? [
                      AppColors.gold,
                      Colors.grey,
                      const Color(0xFFCD7F32)
                    ][rank - 1].withAlpha(40)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('#$rank',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: rank <= 3 && hasActivity
                          ? [
                              AppColors.gold,
                              Colors.grey,
                              const Color(0xFFCD7F32)
                            ][rank - 1]
                          : AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Text(stat.userName[0],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                    '$roleLabel • ${stat.countiesWorked} counties • ${stat.leadsByState.length} states',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                if (stat.undecidedCount > 0)
                  Text('${stat.undecidedCount} undecided follow-ups',
                      style: const TextStyle(
                          color: AppColors.gold, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stat.totalRevenue > 0)
                Text('\$${_formatCurrency(stat.totalRevenue)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold))
              else
                Text('${stat.totalLeadsAssigned} leads',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent)),
              Text(
                  stat.totalSalesCount > 0
                      ? '${stat.totalSalesCount} sales'
                      : '${stat.countiesWorked} counties',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }

  void _showRecordOutcomeDialog(BuildContext context, AppProvider provider) {
    final saleAmountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedStateCode;
    String? selectedCountyName;
    String? selectedAssociateId;
    LeadStatus? selectedDisposition;
    String? errorMessage;
    bool submitting = false;

    final availableAssociates = provider.visibleAssociates;

    showDialog(
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

  Widget _dispositionOption({
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
