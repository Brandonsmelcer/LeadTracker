import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStats();
        final topAgent = stats.isNotEmpty && stats.first.totalLeadsAssigned > 0
            ? stats.first
            : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (topAgent != null) _buildTopAgentHero(topAgent),
            const SizedBox(height: 16),
            _buildOverallStats(provider),
            const SizedBox(height: 16),
            const Text('INDIVIDUAL PERFORMANCE',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (stats.isEmpty || stats.every((s) => s.totalLeadsAssigned == 0))
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
                    Text('Assign leads to team members to see statistics',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            else
              ...stats.asMap().entries.map((entry) {
                final i = entry.key;
                final stat = entry.value;
                return _buildPersonCard(stat, i + 1, provider.totalLeads);
              }),
          ],
        );
      },
    );
  }

  Widget _buildTopAgentHero(dynamic topAgent) {
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
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${topAgent.totalLeadsAssigned} leads • ${topAgent.countiesWorked} counties',
              style: const TextStyle(color: AppColors.accent, fontSize: 16)),
        ],
      ),
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
              Expanded(child: _overviewTile('Total Team', '${provider.users.length}', Icons.groups)),
              Expanded(child: _overviewTile('Managers', '${provider.managers.length}', Icons.supervisor_account)),
              Expanded(child: _overviewTile('Associates', '${provider.associates.length}', Icons.person)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _overviewTile('Total Leads', '${provider.totalLeads}', Icons.trending_up)),
              Expanded(child: _overviewTile('Counties', '${provider.totalCounties}', Icons.map)),
              Expanded(child: _overviewTile('Covered', '${provider.coveredCounties}', Icons.check_circle)),
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
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPersonCard(dynamic stat, int rank, int totalLeads) {
    final pct = totalLeads > 0
        ? ((stat.totalLeadsAssigned / totalLeads) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: rank == 1
            ? Border.all(color: AppColors.gold.withAlpha(100))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? [AppColors.gold, Colors.grey, const Color(0xFFCD7F32)][rank - 1]
                      .withAlpha(40)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: rank <= 3
                        ? [AppColors.gold, Colors.grey, const Color(0xFFCD7F32)][rank - 1]
                        : AppColors.textSecondary,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(stat.userName[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${stat.countiesWorked} counties • $pct% of total',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat.totalLeadsAssigned}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent)),
              const Text('leads',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
