import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStats();
        final topAgent = stats.isNotEmpty && stats.first.totalSales > 0
            ? stats.first
            : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (topAgent != null) _buildTopAgentHero(topAgent),
            const SizedBox(height: 16),
            _buildRevenueCard(provider),
            const SizedBox(height: 16),
            _buildTeamRevenueCards(provider),
            const SizedBox(height: 16),
            _buildOverallStats(provider),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('INDIVIDUAL PERFORMANCE',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: () => _showRecordSaleDialog(context, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Record Sale', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.isEmpty || stats.every((s) => s.totalSales == 0 && s.totalLeadsAssigned == 0))
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.analytics_outlined, size: 48, color: AppColors.countyBorder),
                    SizedBox(height: 12),
                    Text('No stats yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    Text('Record sales or assign leads to see statistics',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            else
              ...stats.asMap().entries.map((entry) =>
                  _buildPersonCard(entry.value, entry.key + 1, provider)),
          ],
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(100)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 40),
          const SizedBox(height: 8),
          const Text('TOP AGENT', style: TextStyle(
              color: AppColors.gold, fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(topAgent.userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_currency.format(topAgent.totalSales),
              style: const TextStyle(color: AppColors.accent, fontSize: 28, fontWeight: FontWeight.bold)),
          Text('${topAgent.salesCount} sales • ${topAgent.totalLeadsAssigned} leads',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(AppProvider provider) {
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
          const Text('TOTAL REVENUE', style: TextStyle(
              color: AppColors.textSecondary, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(_currency.format(provider.totalRevenue),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.accent)),
          Text('${provider.sales.length} total sales',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTeamRevenueCards(AppProvider provider) {
    final managers = provider.managers;
    if (managers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEAM REVENUE', style: TextStyle(
            color: AppColors.gold, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...managers.map((m) {
          final teamRevenue = provider.getTeamRevenue(m.id);
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
                  child: Text(m.name[0], style: const TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${m.name}'s Team", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${teamMembers.length} associates',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_currency.format(teamRevenue),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
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
        color: AppColors.cardDark, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TEAM OVERVIEW', style: TextStyle(
              color: AppColors.gold, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _overviewTile('Team', '${provider.users.length}', Icons.groups)),
              Expanded(child: _overviewTile('Managers', '${provider.managers.length}', Icons.supervisor_account)),
              Expanded(child: _overviewTile('Associates', '${provider.associates.length}', Icons.person)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _overviewTile('Leads', '${provider.totalLeads}', Icons.trending_up)),
              Expanded(child: _overviewTile('Counties', '${provider.totalCounties}', Icons.map)),
              Expanded(child: _overviewTile('Sales', '${provider.sales.length}', Icons.attach_money)),
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
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPersonCard(PersonStats stat, int rank, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark, borderRadius: BorderRadius.circular(12),
        border: rank == 1 && stat.totalSales > 0
            ? Border.all(color: AppColors.gold.withAlpha(100)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 && stat.totalSales > 0
                  ? [AppColors.gold, Colors.grey, const Color(0xFFCD7F32)][rank - 1].withAlpha(40)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('#$rank', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11,
                color: rank <= 3 && stat.totalSales > 0
                    ? [AppColors.gold, Colors.grey, const Color(0xFFCD7F32)][rank - 1]
                    : AppColors.textSecondary))),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16, backgroundColor: AppColors.accent,
            child: Text(stat.userName[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${stat.role.name} • ${stat.salesCount} sales • ${stat.countiesWorked} counties',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currency.format(stat.totalSales),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
              Text('${stat.totalLeadsAssigned} leads',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordSaleDialog(BuildContext context, AppProvider provider) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedAssociateId;
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Record Sale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Sale Amount (\$)',
                    prefixText: '\$ ',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: provider.associates.any((u) => u.id == selectedAssociateId) ? selectedAssociateId : null,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Associate'),
                  items: provider.associates
                      .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: (v) => setD(() {
                    selectedAssociateId = v;
                    if (v != null) {
                      final assoc = provider.associates.firstWhere((a) => a.id == v);
                      selectedManagerId = assoc.managerId;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedManagerId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Manager'),
                  items: provider.managers
                      .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: (v) => setD(() => selectedManagerId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount > 0 && selectedAssociateId != null && selectedManagerId != null) {
                  provider.recordSale(
                    selectedAssociateId!, selectedManagerId!, amount,
                    description: descCtrl.text,
                  );
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
