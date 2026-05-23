import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifeLeadMapApp());
}

const List<RegionState> regionStates = <RegionState>[
  RegionState(
    code: 'WV',
    fips: '54',
    name: 'West Virginia',
    accent: Color(0xFF2F6B4F),
  ),
  RegionState(
    code: 'TN',
    fips: '47',
    name: 'Tennessee',
    accent: Color(0xFFB46D2A),
  ),
  RegionState(
    code: 'KY',
    fips: '21',
    name: 'Kentucky',
    accent: Color(0xFF335C9A),
  ),
];

final Map<String, RegionState> statesByCode = <String, RegionState>{
  for (final state in regionStates) state.code: state,
};

const Map<String, String> stateCodeByFips = <String, String>{
  '54': 'WV',
  '47': 'TN',
  '21': 'KY',
};

class LifeLeadMapApp extends StatelessWidget {
  const LifeLeadMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Lead Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF124436),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F0E8),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9F6EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LeadMapHomePage(),
    );
  }
}

class LeadMapHomePage extends StatefulWidget {
  const LeadMapHomePage({super.key});

  @override
  State<LeadMapHomePage> createState() => _LeadMapHomePageState();
}

class _LeadMapHomePageState extends State<LeadMapHomePage> {
  AppData? _data;
  String _selectedState = 'ALL';
  String _searchText = '';
  bool _showCountyNames = true;
  String? _selectedFips;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rawGeoJson = await rootBundle.loadString(
      'assets/counties_wv_tn_ky.geojson',
    );
    final preferences = await SharedPreferences.getInstance();
    final counties = CountyFeatureParser.parse(rawGeoJson);
    final store = LeadStore(preferences);
    final records = await store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _data = AppData(counties: counties, records: records, store: store);
    });
  }

  List<CountyFeature> _visibleCounties(AppData data) {
    final stateFiltered = _selectedState == 'ALL'
        ? data.counties
        : data.counties.where((county) => county.stateCode == _selectedState);
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return stateFiltered.toList();
    }
    return stateFiltered
        .where(
          (county) =>
              county.name.toLowerCase().contains(query) ||
              county.fips.contains(query) ||
              county.stateCode.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _saveRecord(CountyFeature county, LeadRecord record) async {
    final data = _data;
    if (data == null) {
      return;
    }
    setState(() {
      _selectedFips = county.fips;
      if (record.isEmpty) {
        data.records.remove(county.fips);
      } else {
        data.records[county.fips] = record;
      }
    });
    await data.store.save(data.records);
  }

  Future<void> _openCountyEditor(CountyFeature county) async {
    final data = _data;
    if (data == null) {
      return;
    }
    setState(() => _selectedFips = county.fips);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CountyEditorSheet(
          county: county,
          initialRecord: data.records[county.fips] ?? LeadRecord.empty(),
          onSave: (record) => _saveRecord(county, record),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final visibleCounties = _visibleCounties(data);
    final selectedCounties = _selectedState == 'ALL'
        ? data.counties
        : data.counties
              .where((county) => county.stateCode == _selectedState)
              .toList();
    final summary = TerritorySummary.from(data.counties, data.records);
    final selectedSummary = TerritorySummary.from(
      selectedCounties,
      data.records,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: HeaderPanel(
                summary: summary,
                selectedSummary: selectedSummary,
                selectedState: _selectedState,
                onStateChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedFips = null;
                  });
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: MapSection(
                  counties: selectedCounties,
                  records: data.records,
                  selectedFips: _selectedFips,
                  showCountyNames: _showCountyNames,
                  onToggleLabels: (value) {
                    setState(() => _showCountyNames = value);
                  },
                  onCountyTap: _openCountyEditor,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: CountySearchBar(
                  searchText: _searchText,
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList.separated(
                itemCount: visibleCounties.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final county = visibleCounties[index];
                  return CountyLeadCard(
                    county: county,
                    record: data.records[county.fips] ?? LeadRecord.empty(),
                    isSelected: county.fips == _selectedFips,
                    onTap: () => _openCountyEditor(county),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    required this.summary,
    required this.selectedSummary,
    required this.selectedState,
    required this.onStateChanged,
    super.key,
  });

  final TerritorySummary summary;
  final TerritorySummary selectedSummary;
  final String selectedState;
  final ValueChanged<String> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedState == 'ALL'
        ? 'WV, TN, and KY territory'
        : statesByCode[selectedState]!.name;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F392F), Color(0xFF1D6A55)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F392F).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Southern Life Lead Map',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A flat FIPS county map for life insurance lead ownership across West Virginia, Tennessee, and Kentucky.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: selectedState,
            iconEnabledColor: Colors.white,
            dropdownColor: const Color(0xFF123C32),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Choose map view',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              prefixIcon: Icon(
                Icons.map_outlined,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'ALL', child: Text('All states merged')),
              DropdownMenuItem(value: 'WV', child: Text('West Virginia')),
              DropdownMenuItem(value: 'TN', child: Text('Tennessee')),
              DropdownMenuItem(value: 'KY', child: Text('Kentucky')),
            ],
            onChanged: (value) {
              if (value != null) {
                onStateChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            selectedLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricPill(
                  label: 'Leads',
                  value: selectedSummary.totalLeads.toString(),
                  icon: Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: 'Owned',
                  value: selectedSummary.assignedCount.toString(),
                  icon: Icons.assignment_ind_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: 'Counties',
                  value: selectedSummary.countyCount.toString(),
                  icon: Icons.grid_view_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Total book: ${summary.totalLeads} leads across ${summary.countyCount} counties.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white.withValues(alpha: 0.78), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MapSection extends StatelessWidget {
  const MapSection({
    required this.counties,
    required this.records,
    required this.selectedFips,
    required this.showCountyNames,
    required this.onToggleLabels,
    required this.onCountyTap,
    super.key,
  });

  final List<CountyFeature> counties;
  final Map<String, LeadRecord> records;
  final String? selectedFips;
  final bool showCountyNames;
  final ValueChanged<bool> onToggleLabels;
  final ValueChanged<CountyFeature> onCountyTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'FIPS county territory map',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1F2B26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any county shape to edit lead owner, lead number, and notes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF66706A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: showCountyNames,
                  label: const Text('Names'),
                  avatar: const Icon(Icons.text_fields, size: 18),
                  onSelected: onToggleLabels,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.05,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TerritoryMap(
                counties: counties,
                records: records,
                selectedFips: selectedFips,
                showCountyNames: showCountyNames,
                onCountyTap: onCountyTap,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                const MapLegendItem(
                  color: Color(0xFFF7E7C4),
                  label: 'Open county',
                ),
                const MapLegendItem(
                  color: Color(0xFFE4B14A),
                  label: 'Leads entered',
                ),
                const MapLegendItem(
                  color: Color(0xFF21634F),
                  label: 'Owner assigned',
                ),
                for (final state in regionStates)
                  MapLegendItem(color: state.accent, label: state.code),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapLegendItem extends StatelessWidget {
  const MapLegendItem({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF42504A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TerritoryMap extends StatelessWidget {
  const TerritoryMap({
    required this.counties,
    required this.records,
    required this.selectedFips,
    required this.showCountyNames,
    required this.onCountyTap,
    super.key,
  });

  final List<CountyFeature> counties;
  final Map<String, LeadRecord> records;
  final String? selectedFips;
  final bool showCountyNames;
  final ValueChanged<CountyFeature> onCountyTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final hit = CountyHitTester.hitTest(
              counties: counties,
              canvasSize: size,
              position: details.localPosition,
            );
            if (hit != null) {
              onCountyTap(hit);
            }
          },
          child: CustomPaint(
            size: size,
            painter: TerritoryMapPainter(
              counties: counties,
              records: records,
              selectedFips: selectedFips,
              showCountyNames: showCountyNames,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class TerritoryMapPainter extends CustomPainter {
  TerritoryMapPainter({
    required this.counties,
    required this.records,
    required this.selectedFips,
    required this.showCountyNames,
  });

  final List<CountyFeature> counties;
  final Map<String, LeadRecord> records;
  final String? selectedFips;
  final bool showCountyNames;

  @override
  void paint(Canvas canvas, Size size) {
    if (counties.isEmpty || size.isEmpty) {
      return;
    }

    final projection = MapProjection.forCounties(counties, size);
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF9F3E6), Color(0xFFEAF2EA)],
      ).createShader(Offset.zero & size);
    final rounded = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(rounded, background);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final county in counties) {
      final path = CountyPathBuilder.pathFor(
        county,
        projection,
      ).shift(const Offset(0, 3));
      canvas.drawPath(path, shadowPaint);
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = Colors.white.withValues(alpha: 0.92);

    for (final county in counties) {
      final record = records[county.fips] ?? LeadRecord.empty();
      final path = CountyPathBuilder.pathFor(county, projection);
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _fillColor(county, record);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    final stateBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF1C332A).withValues(alpha: 0.42);
    for (final county in counties) {
      final path = CountyPathBuilder.pathFor(county, projection);
      canvas.drawPath(path, stateBorderPaint);
    }

    if (selectedFips != null) {
      final selectedCounty = counties
          .where((county) => county.fips == selectedFips)
          .firstOrNull;
      if (selectedCounty != null) {
        final selectedPath = CountyPathBuilder.pathFor(
          selectedCounty,
          projection,
        );
        canvas.drawPath(
          selectedPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..color = const Color(0xFFFFD46B),
        );
      }
    }

    if (showCountyNames) {
      _paintLabels(canvas, projection);
    }
  }

  Color _fillColor(CountyFeature county, LeadRecord record) {
    final stateColor = statesByCode[county.stateCode]!.accent;
    if (record.owner.trim().isNotEmpty) {
      return Color.lerp(stateColor, const Color(0xFF19483B), 0.42)!;
    }
    if (record.leadCount > 0) {
      final strength = (record.leadCount / 50).clamp(0.18, 0.82).toDouble();
      return Color.lerp(
        const Color(0xFFF7E7C4),
        const Color(0xFFE3A72F),
        strength,
      )!;
    }
    return Color.lerp(Colors.white, stateColor, 0.28)!;
  }

  void _paintLabels(Canvas canvas, MapProjection projection) {
    final manyCounties = counties.length > 125;
    for (final county in counties) {
      final record = records[county.fips] ?? LeadRecord.empty();
      final shouldEmphasize = record.hasActivity || county.fips == selectedFips;
      final fontSize = manyCounties && !shouldEmphasize ? 5.4 : 7.5;
      final centroid = projection.toCanvas(county.labelPoint);
      final labelText = manyCounties && !shouldEmphasize
          ? county.nameAbbreviation
          : county.name;
      final painter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: const Color(
              0xFF16231E,
            ).withValues(alpha: shouldEmphasize ? 0.95 : 0.66),
            fontSize: fontSize,
            fontWeight: shouldEmphasize ? FontWeight.w800 : FontWeight.w600,
            height: 1,
          ),
        ),
        maxLines: 1,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 58);

      final offset = Offset(
        centroid.dx - painter.width / 2,
        centroid.dy - painter.height / 2,
      );
      if (shouldEmphasize) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx - 3,
            offset.dy - 2,
            painter.width + 6,
            painter.height + 4,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = Colors.white.withValues(alpha: 0.82),
        );
      }
      painter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant TerritoryMapPainter oldDelegate) {
    return oldDelegate.counties != counties ||
        oldDelegate.records != records ||
        oldDelegate.selectedFips != selectedFips ||
        oldDelegate.showCountyNames != showCountyNames;
  }
}

class CountySearchBar extends StatelessWidget {
  const CountySearchBar({
    required this.searchText,
    required this.onChanged,
    super.key,
  });

  final String searchText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Search county, FIPS, or state...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

class CountyLeadCard extends StatelessWidget {
  const CountyLeadCard({
    required this.county,
    required this.record,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final CountyFeature county;
  final LeadRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = statesByCode[county.stateCode]!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFFE5B94C) : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: state.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  state.code,
                  style: TextStyle(
                    color: state.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${county.name} County',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1F2B26),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${state.name} / FIPS ${county.fips}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF69736D),
                      ),
                    ),
                    if (record.owner.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'Owner: ${record.owner}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF315E4F),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    record.leadCount.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: record.leadCount > 0
                          ? const Color(0xFFB3761D)
                          : const Color(0xFFADB3AE),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'leads',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF69736D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountyEditorSheet extends StatefulWidget {
  const CountyEditorSheet({
    required this.county,
    required this.initialRecord,
    required this.onSave,
    super.key,
  });

  final CountyFeature county;
  final LeadRecord initialRecord;
  final ValueChanged<LeadRecord> onSave;

  @override
  State<CountyEditorSheet> createState() => _CountyEditorSheetState();
}

class _CountyEditorSheetState extends State<CountyEditorSheet> {
  late final TextEditingController _ownerController;
  late final TextEditingController _leadController;
  late final TextEditingController _notesController;
  late bool _priority;

  @override
  void initState() {
    super.initState();
    _ownerController = TextEditingController(text: widget.initialRecord.owner);
    _leadController = TextEditingController(
      text: widget.initialRecord.leadCount == 0
          ? ''
          : widget.initialRecord.leadCount.toString(),
    );
    _notesController = TextEditingController(text: widget.initialRecord.notes);
    _priority = widget.initialRecord.priority;
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _leadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final record = LeadRecord(
      owner: _ownerController.text.trim(),
      leadCount: int.tryParse(_leadController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
      priority: _priority,
    );
    widget.onSave(record);
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onSave(LeadRecord.empty());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = statesByCode[widget.county.stateCode]!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D2C8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: state.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      state.code,
                      style: TextStyle(
                        color: state.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${widget.county.name} County',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF17251F),
                              ),
                        ),
                        Text(
                          '${state.name} / FIPS ${widget.county.fips}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF69736D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ownerController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Lead owner / agent name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _leadController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Lead count',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Life insurance notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _priority,
                onChanged: (value) => setState(() => _priority = value),
                title: const Text('Priority market'),
                subtitle: const Text(
                  'Use this for counties the agency wants to work first.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save county'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppData {
  AppData({required this.counties, required this.records, required this.store});

  final List<CountyFeature> counties;
  final Map<String, LeadRecord> records;
  final LeadStore store;
}

class TerritorySummary {
  const TerritorySummary({
    required this.totalLeads,
    required this.assignedCount,
    required this.countyCount,
  });

  final int totalLeads;
  final int assignedCount;
  final int countyCount;

  factory TerritorySummary.from(
    Iterable<CountyFeature> counties,
    Map<String, LeadRecord> records,
  ) {
    var totalLeads = 0;
    var assignedCount = 0;
    var countyCount = 0;
    for (final county in counties) {
      countyCount += 1;
      final record = records[county.fips] ?? LeadRecord.empty();
      totalLeads += record.leadCount;
      if (record.owner.trim().isNotEmpty) {
        assignedCount += 1;
      }
    }
    return TerritorySummary(
      totalLeads: totalLeads,
      assignedCount: assignedCount,
      countyCount: countyCount,
    );
  }
}

class RegionState {
  const RegionState({
    required this.code,
    required this.fips,
    required this.name,
    required this.accent,
  });

  final String code;
  final String fips;
  final String name;
  final Color accent;
}

class LeadRecord {
  const LeadRecord({
    required this.owner,
    required this.leadCount,
    required this.notes,
    required this.priority,
  });

  final String owner;
  final int leadCount;
  final String notes;
  final bool priority;

  bool get hasActivity =>
      owner.trim().isNotEmpty ||
      leadCount > 0 ||
      notes.trim().isNotEmpty ||
      priority;
  bool get isEmpty => !hasActivity;

  factory LeadRecord.empty() {
    return const LeadRecord(
      owner: '',
      leadCount: 0,
      notes: '',
      priority: false,
    );
  }

  factory LeadRecord.fromJson(Map<String, dynamic> json) {
    return LeadRecord(
      owner: (json['owner'] as String?) ?? '',
      leadCount: (json['leadCount'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as String?) ?? '',
      priority: (json['priority'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'owner': owner,
      'leadCount': leadCount,
      'notes': notes,
      'priority': priority,
    };
  }
}

class LeadStore {
  LeadStore(this._preferences);

  static const String _storageKey = 'lifeLeadMap.countyRecords.v1';

  final SharedPreferences _preferences;

  Future<Map<String, LeadRecord>> load() async {
    final rawValue = _preferences.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return <String, LeadRecord>{};
    }
    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map((key, value) {
      return MapEntry(
        key,
        LeadRecord.fromJson(
          Map<String, dynamic>.from(value as Map<dynamic, dynamic>),
        ),
      );
    });
  }

  Future<void> save(Map<String, LeadRecord> records) async {
    final encoded = records.map(
      (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
    );
    await _preferences.setString(_storageKey, jsonEncode(encoded));
  }
}

class CountyFeature {
  CountyFeature({
    required this.fips,
    required this.name,
    required this.stateCode,
    required this.polygons,
    required this.labelPoint,
  });

  final String fips;
  final String name;
  final String stateCode;
  final List<List<List<GeoPoint>>> polygons;
  final GeoPoint labelPoint;

  String get nameAbbreviation {
    final cleaned = name.replaceAll(RegExp('[^A-Za-z]'), '');
    if (cleaned.length <= 4) {
      return cleaned;
    }
    return cleaned.substring(0, math.min(4, cleaned.length));
  }
}

class GeoPoint {
  const GeoPoint(this.longitude, this.latitude);

  final double longitude;
  final double latitude;
}

class CountyFeatureParser {
  static List<CountyFeature> parse(String rawGeoJson) {
    final decoded = jsonDecode(rawGeoJson) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>;
    final counties =
        features.map((feature) {
          final featureMap = feature as Map<String, dynamic>;
          final properties = featureMap['properties'] as Map<String, dynamic>;
          final fips = featureMap['id'].toString().padLeft(5, '0');
          final stateFips = properties['STATE'].toString().padLeft(2, '0');
          final stateCode = stateCodeByFips[stateFips];
          if (stateCode == null) {
            throw FormatException('Unexpected state FIPS: $stateFips');
          }
          final polygons = _parseGeometry(
            featureMap['geometry'] as Map<String, dynamic>,
          );
          return CountyFeature(
            fips: fips,
            name: properties['NAME'] as String,
            stateCode: stateCode,
            polygons: polygons,
            labelPoint: _labelPoint(polygons),
          );
        }).toList()..sort((left, right) {
          final stateCompare = _stateSort(
            left.stateCode,
          ).compareTo(_stateSort(right.stateCode));
          if (stateCompare != 0) {
            return stateCompare;
          }
          return left.name.compareTo(right.name);
        });
    return counties;
  }

  static int _stateSort(String code) {
    return regionStates.indexWhere((state) => state.code == code);
  }

  static List<List<List<GeoPoint>>> _parseGeometry(
    Map<String, dynamic> geometry,
  ) {
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    if (type == 'Polygon') {
      return <List<List<GeoPoint>>>[_parsePolygon(coordinates)];
    }
    if (type == 'MultiPolygon') {
      return coordinates
          .map((polygon) => _parsePolygon(polygon as List<dynamic>))
          .toList();
    }
    throw FormatException('Unsupported geometry type: $type');
  }

  static List<List<GeoPoint>> _parsePolygon(List<dynamic> rings) {
    return rings.map((ring) {
      return (ring as List<dynamic>).map((point) {
        final values = point as List<dynamic>;
        return GeoPoint(
          (values[0] as num).toDouble(),
          (values[1] as num).toDouble(),
        );
      }).toList();
    }).toList();
  }

  static GeoPoint _labelPoint(List<List<List<GeoPoint>>> polygons) {
    var totalLongitude = 0.0;
    var totalLatitude = 0.0;
    var count = 0;
    for (final polygon in polygons) {
      if (polygon.isEmpty) {
        continue;
      }
      for (final point in polygon.first) {
        totalLongitude += point.longitude;
        totalLatitude += point.latitude;
        count += 1;
      }
    }
    if (count == 0) {
      return const GeoPoint(0, 0);
    }
    return GeoPoint(totalLongitude / count, totalLatitude / count);
  }
}

class MapProjection {
  MapProjection({
    required this.bounds,
    required this.scale,
    required this.offset,
  });

  final Rect bounds;
  final double scale;
  final Offset offset;

  factory MapProjection.forCounties(List<CountyFeature> counties, Size size) {
    var minLongitude = double.infinity;
    var maxLongitude = -double.infinity;
    var minLatitude = double.infinity;
    var maxLatitude = -double.infinity;

    for (final county in counties) {
      for (final polygon in county.polygons) {
        for (final ring in polygon) {
          for (final point in ring) {
            minLongitude = math.min(minLongitude, point.longitude);
            maxLongitude = math.max(maxLongitude, point.longitude);
            minLatitude = math.min(minLatitude, point.latitude);
            maxLatitude = math.max(maxLatitude, point.latitude);
          }
        }
      }
    }

    final bounds = Rect.fromLTRB(
      minLongitude,
      minLatitude,
      maxLongitude,
      maxLatitude,
    );
    const padding = 16.0;
    final widthScale = (size.width - padding * 2) / bounds.width;
    final heightScale = (size.height - padding * 2) / bounds.height;
    final scale = math.min(widthScale, heightScale);
    final mapWidth = bounds.width * scale;
    final mapHeight = bounds.height * scale;
    final offset = Offset(
      (size.width - mapWidth) / 2,
      (size.height - mapHeight) / 2,
    );
    return MapProjection(bounds: bounds, scale: scale, offset: offset);
  }

  Offset toCanvas(GeoPoint point) {
    final x = offset.dx + (point.longitude - bounds.left) * scale;
    final y = offset.dy + (bounds.bottom - point.latitude) * scale;
    return Offset(x, y);
  }
}

class CountyPathBuilder {
  static Path pathFor(CountyFeature county, MapProjection projection) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in county.polygons) {
      for (final ring in polygon) {
        if (ring.length < 3) {
          continue;
        }
        path.addPolygon(ring.map(projection.toCanvas).toList(), true);
      }
    }
    return path;
  }
}

class CountyHitTester {
  static CountyFeature? hitTest({
    required List<CountyFeature> counties,
    required Size canvasSize,
    required Offset position,
  }) {
    if (counties.isEmpty || canvasSize.isEmpty) {
      return null;
    }
    final projection = MapProjection.forCounties(counties, canvasSize);
    for (final county in counties.reversed) {
      final path = CountyPathBuilder.pathFor(county, projection);
      if (path.contains(position)) {
        return county;
      }
    }
    return null;
  }
}
