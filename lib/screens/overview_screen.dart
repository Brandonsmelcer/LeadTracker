import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(provider),
              const SizedBox(height: 16),
              _buildStateCards(provider),
              const SizedBox(height: 16),
              _buildTopAgentsCard(provider),
              const SizedBox(height: 16),
              _buildRecentActivity(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Text('VISION TO LEGACY',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('\$${_formatNumber(provider.totalLeads)}',
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Text('TOTAL LEADS',
              style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip(Icons.map, '${provider.states.length}', 'States'),
              _statChip(Icons.grid_view, '${provider.totalCounties}', 'Counties'),
              _statChip(Icons.check_circle, '${provider.coveredCounties}', 'Covered'),
              _statChip(Icons.groups, '${provider.users.length}', 'Team'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStateCards(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STATE BREAKDOWN',
            style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...provider.states.map((state) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(state.code,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${state.counties.length} counties',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${state.totalLeads}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent)),
                      Text('${state.coveragePercent.toStringAsFixed(0)}% covered',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTopAgentsCard(AppProvider provider) {
    final stats = provider.getStats();
    final topAgents = stats.where((s) => s.totalLeadsAssigned > 0).take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text('TOP AGENTS',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (topAgents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No leads assigned yet',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...topAgents.asMap().entries.map((entry) {
              final i = entry.key;
              final stat = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('#${i + 1}',
                          style: TextStyle(
                              color: i == 0 ? AppColors.gold : AppColors.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(stat.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Text('${stat.totalLeadsAssigned} leads',
                        style: const TextStyle(
                            color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AppProvider provider) {
    final recentNotes = provider.notes.reversed.take(5).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text('RECENT NOTES',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (recentNotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No notes yet — add one from the Notes section',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...recentNotes.map((note) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accent,
                        child: Text(note.authorName[0],
                            style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note.authorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(note.content,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
