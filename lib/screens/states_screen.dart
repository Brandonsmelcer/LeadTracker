import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/county_map_geometry.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/county_detail_dialog.dart';
import '../widgets/county_svg_map.dart';

enum MapViewMode { combined, tennessee, kentucky, westVirginia }

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  MapViewMode _viewMode = MapViewMode.combined;
  bool _showMap = true;
  String _searchQuery = '';
  CountyMapGeometry? _geometry;
  bool _loading = true;
  String? _loadError;
  int _tabLength = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadGeometry();
  }

  Future<void> _loadGeometry() async {
    try {
      final geometry = await CountyMapGeometry.load();
      if (mounted) {
        setState(() {
          _geometry = geometry;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _syncTabsForRole(AppProvider provider) {
    final modes = _modesForRole(provider);
    if (_tabLength == modes.length) return;
    _tabLength = modes.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(length: modes.length, vsync: this);
      _tabController.addListener(_onTabChanged);
      setState(() => _viewMode = modes.first);
    });
  }

  List<MapViewMode> _modesForRole(AppProvider provider) {
    if (provider.canViewCombinedMap) {
      return MapViewMode.values;
    }
    return [
      MapViewMode.tennessee,
      MapViewMode.kentucky,
      MapViewMode.westVirginia,
    ];
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = context.read<AppProvider>();
      final modes = _modesForRole(provider);
      setState(() => _viewMode = modes[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  CountyMapLayer? _layerForMode(MapViewMode mode, AppProvider provider) {
    if (_geometry == null) return null;
    return switch (mode) {
      MapViewMode.combined =>
        provider.canViewCombinedMap ? _geometry!.combined : null,
      MapViewMode.tennessee => _geometry!.layerFor('TN'),
      MapViewMode.kentucky => _geometry!.layerFor('KY'),
      MapViewMode.westVirginia => _geometry!.layerFor('WV'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.canAccessMap) {
          return const Center(
            child: Text(
              'Map access is restricted to administrators.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        _syncTabsForRole(provider);
        final modes = _modesForRole(provider);
        final layer = _layerForMode(_viewMode, provider);

        return Column(
          children: [
            _buildHeader(provider),
            _buildScopeBanner(provider),
            if (_tabController.length == modes.length)
              _buildViewToggle(modes)
            else
              const SizedBox(height: 48),
            if (!provider.canEditMap)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Chip(
                    label: Text('View Only',
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.surface,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_showMap ? Icons.list : Icons.map),
                    tooltip: _showMap ? 'List View' : 'Map View',
                    onPressed: () => setState(() => _showMap = !_showMap),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(provider, layer)),
          ],
        );
      },
    );
  }

  Widget _buildScopeBanner(AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.secondary,
      child: Text(
        provider.mapScopeLabel,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
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
          _headerStat(
              'Visible Leads', '${provider.visibleTotalLeads}', AppColors.accent),
          _headerStat('Counties', '${provider.totalCounties}', AppColors.gold),
          _headerStat(
              'Covered', '${provider.visibleCoveredCounties}', AppColors.success),
          _headerStat('States', '${provider.states.length}', AppColors.warning),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildViewToggle(List<MapViewMode> modes) {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.accent,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: modes.map((m) => Tab(text: _tabLabel(m))).toList(),
      ),
    );
  }

  String _tabLabel(MapViewMode mode) => switch (mode) {
        MapViewMode.combined => 'Combined',
        MapViewMode.tennessee => 'Tennessee',
        MapViewMode.kentucky => 'Kentucky',
        MapViewMode.westVirginia => 'West Virginia',
      };

  Widget _buildBody(AppProvider provider, CountyMapLayer? layer) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_loadError != null) {
      return Center(
        child: Text('Failed to load map: $_loadError',
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    if (layer == null) {
      return const Center(child: Text('Map data unavailable'));
    }

    if (!_showMap) {
      return _CountyListPanel(
        provider: provider,
        viewMode: _viewMode,
        searchQuery: _searchQuery,
      );
    }

    return CountySvgMap(
      layer: layer,
      provider: provider,
      searchQuery: _searchQuery,
    );
  }
}

class _CountyListPanel extends StatelessWidget {
  final AppProvider provider;
  final MapViewMode viewMode;
  final String searchQuery;

  const _CountyListPanel({
    required this.provider,
    required this.viewMode,
    required this.searchQuery,
  });

  List<String> get _stateCodes {
    final modes = switch (viewMode) {
      MapViewMode.combined => ['TN', 'KY', 'WV'],
      MapViewMode.tennessee => ['TN'],
      MapViewMode.kentucky => ['KY'],
      MapViewMode.westVirginia => ['WV'],
    };
    return modes;
  }

  @override
  Widget build(BuildContext context) {
    final counties = <({County county, String stateCode})>[];
    for (final code in _stateCodes) {
      final state = provider.states.firstWhere((s) => s.code == code);
      for (final c in state.counties) {
        if (!provider.isCountyVisibleOnMap(c) &&
            provider.currentUser.role != UserRole.admin) {
          continue;
        }
        if (searchQuery.isEmpty ||
            c.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          counties.add((county: c, stateCode: code));
        }
      }
    }
    counties.sort((a, b) => provider
        .mapVisibleLeadCount(b.county)
        .compareTo(provider.mapVisibleLeadCount(a.county)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: counties.length,
      itemBuilder: (context, index) {
        final item = counties[index];
        final county = item.county;
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: county.leadCount > 0
                    ? AppColors.accent.withAlpha(40)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${provider.mapVisibleLeadCount(county)}',
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
            subtitle: Text(
              '${item.stateCode}${assignee != null ? ' • ${assignee.name}' : ''}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: () {
              CountyDetailDialog.show(
                context,
                county: county,
                stateCode: item.stateCode,
                provider: provider,
              );
            },
          ),
        );
      },
    );
  }
}
