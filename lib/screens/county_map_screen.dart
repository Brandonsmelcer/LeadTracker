import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/county_map_geometry.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/county_svg_map.dart';

/// Individual state county map (navigated from deep links).
/// The main multi-state map lives in [StatesScreen].
class CountyMapScreen extends StatefulWidget {
  final StateData stateData;
  const CountyMapScreen({super.key, required this.stateData});

  @override
  State<CountyMapScreen> createState() => _CountyMapScreenState();
}

class _CountyMapScreenState extends State<CountyMapScreen> {
  String _searchQuery = '';
  CountyMapGeometry? _geometry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CountyMapGeometry.load().then((g) {
      if (mounted) {
        setState(() {
          _geometry = g;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.canAccessMap) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.stateData.name)),
            body: const Center(
              child: Text(
                'Map access is restricted to administrators.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final state = provider.states.firstWhere(
            (s) => s.code == widget.stateData.code);
        final layer = _geometry?.layerFor(state.code);

        return Scaffold(
          appBar: AppBar(
            title: Text(state.name),
            actions: [
              if (!provider.canEditMap)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('View Only',
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.surface,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(state),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search counties...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    hintStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : layer == null
                        ? const Center(
                            child: Text('Map data unavailable',
                                style: TextStyle(
                                    color: AppColors.textSecondary)))
                        : ClipRect(
                            clipBehavior: Clip.none,
                            child: CountySvgMap(
                              layer: layer,
                              provider: provider,
                              searchQuery: _searchQuery,
                            ),
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
