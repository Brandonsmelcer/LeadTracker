import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CountyMapScreen extends StatefulWidget {
  final StateData stateData;
  const CountyMapScreen({super.key, required this.stateData});

  @override
  State<CountyMapScreen> createState() => _CountyMapScreenState();
}

class _CountyMapScreenState extends State<CountyMapScreen> {
  bool _showMap = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final state = provider.states.firstWhere(
            (s) => s.code == widget.stateData.code);

        final filteredCounties = _searchQuery.isEmpty
            ? state.counties
            : state.counties
                .where((c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(state.name),
            actions: [
              IconButton(
                icon: Icon(_showMap ? Icons.list : Icons.grid_view),
                onPressed: () => setState(() => _showMap = !_showMap),
                tooltip: _showMap ? 'List View' : 'Map View',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(state),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search counties...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: _showMap
                    ? _CountyGridMap(
                        counties: filteredCounties,
                        stateCode: state.code,
                        provider: provider,
                      )
                    : _CountyListView(
                        counties: filteredCounties,
                        stateCode: state.code,
                        provider: provider,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(StateData state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.surface],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _headerStat('Total Leads', '${state.totalLeads}', AppColors.accent),
          _headerStat('Counties', '${state.counties.length}', AppColors.gold),
          _headerStat(
              'Covered', '${state.coveredCounties}', AppColors.success),
          _headerStat(
              'Coverage', '${state.coveragePercent.toStringAsFixed(0)}%',
              AppColors.warning),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CountyGridMap extends StatelessWidget {
  final List<County> counties;
  final String stateCode;
  final AppProvider provider;

  const _CountyGridMap({
    required this.counties,
    required this.stateCode,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: counties.length,
      itemBuilder: (context, index) {
        final county = counties[index];
        return _CountyTile(
          county: county,
          stateCode: stateCode,
          provider: provider,
        );
      },
    );
  }
}

class _CountyTile extends StatelessWidget {
  final County county;
  final String stateCode;
  final AppProvider provider;

  const _CountyTile({
    required this.county,
    required this.stateCode,
    required this.provider,
  });

  Color _getHeatColor(int leads) {
    if (leads == 0) return AppColors.countyFill;
    if (leads < 10) return const Color(0xFF1B5E20);
    if (leads < 50) return const Color(0xFF2E7D32);
    if (leads < 100) return const Color(0xFF388E3C);
    if (leads < 500) return const Color(0xFFFF8F00);
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final hasLeads = county.leadCount > 0;
    final assignee = county.assignedTo != null
        ? provider.users.cast<AppUser?>().firstWhere(
            (u) => u!.id == county.assignedTo,
            orElse: () => null)
        : null;

    return GestureDetector(
      onTap: () => _showCountyDialog(context),
      child: CustomPaint(
        painter: _HexPainter(
          fillColor: _getHeatColor(county.leadCount),
          borderColor: hasLeads ? AppColors.gold.withAlpha(150) : AppColors.countyBorder,
          borderWidth: hasLeads ? 2.0 : 1.0,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  county.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: county.name.length > 10 ? 9 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasLeads) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${county.leadCount}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (assignee != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      assignee.name.split(' ').first,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 8),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCountyDialog(BuildContext context) {
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
                            style: TextStyle(color: AppColors.textSecondary))),
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
}

class _HexPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _HexPainter({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) * 0.95;

    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.fillColor != fillColor || old.borderColor != borderColor;
}

class _CountyListView extends StatelessWidget {
  final List<County> counties;
  final String stateCode;
  final AppProvider provider;

  const _CountyListView({
    required this.counties,
    required this.stateCode,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<County>.from(counties)
      ..sort((a, b) => b.leadCount.compareTo(a.leadCount));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final county = sorted[index];
        final assignee = county.assignedTo != null
            ? provider.users.cast<AppUser?>().firstWhere(
                (u) => u!.id == county.assignedTo,
                orElse: () => null)
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: county.leadCount > 0
                    ? AppColors.accent.withAlpha(40)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${county.leadCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: county.leadCount > 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            title: Text(county.name),
            subtitle: assignee != null
                ? Text('Assigned: ${assignee.name}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12))
                : null,
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: () {
              _CountyTile(
                county: county,
                stateCode: stateCode,
                provider: provider,
              )._showCountyDialog(context);
            },
          ),
        );
      },
    );
  }
}
