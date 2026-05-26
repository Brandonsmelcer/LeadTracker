import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../data/county_positions.dart';

class GeoMapScreen extends StatefulWidget {
  final String? filterStateCode;
  const GeoMapScreen({super.key, this.filterStateCode});

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  final TransformationController _transformCtrl = TransformationController();
  String? _selectedCountyId;
  String? _filterState;

  @override
  void initState() {
    super.initState();
    _filterState = widget.filterStateCode;
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Map<String, CountyPosition> _getPositions(String code) {
    switch (code) {
      case 'TN': return tnPositions;
      case 'KY': return kyPositions;
      case 'WV': return wvPositions;
      default: return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final statesToShow = _filterState != null
            ? provider.states.where((s) => s.code == _filterState).toList()
            : provider.states;

        final totalLeads = statesToShow.fold(0, (sum, s) => sum + s.totalLeads);
        final totalCounties = statesToShow.fold(0, (sum, s) => sum + s.counties.length);
        final coveredCounties = statesToShow.fold(0, (sum, s) => sum + s.coveredCounties);

        return Scaffold(
          appBar: AppBar(
            title: Text(_filterState != null
                ? '${statesToShow.first.name} Map'
                : 'All States Map'),
            actions: [
              if (widget.filterStateCode == null)
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() => _filterState = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('All States')),
                    const PopupMenuItem(value: 'TN', child: Text('Tennessee')),
                    const PopupMenuItem(value: 'KY', child: Text('Kentucky')),
                    const PopupMenuItem(value: 'WV', child: Text('West Virginia')),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.zoom_out_map),
                onPressed: () => _transformCtrl.value = Matrix4.identity(),
                tooltip: 'Reset zoom',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStatsBar(totalLeads, totalCounties, coveredCounties),
              _buildLegend(),
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.5,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _GeoMapPainter(
                          states: statesToShow,
                          getPositions: _getPositions,
                          provider: provider,
                          selectedCountyId: _selectedCountyId,
                          filterState: _filterState,
                        ),
                        child: GestureDetector(
                          onTapUp: (details) => _handleTap(
                            details, constraints, statesToShow, provider,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_selectedCountyId != null)
                _buildCountyInfoBar(provider, statesToShow),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBar(int leads, int counties, int covered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.surface],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Leads', '$leads', AppColors.accent),
          _stat('Counties', '$counties', AppColors.gold),
          _stat('Covered', '$covered', AppColors.success),
          _stat('Coverage',
              '${counties > 0 ? (covered / counties * 100).toStringAsFixed(0) : 0}%',
              AppColors.warning),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.primary.withAlpha(180),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(AppColors.countyFill, 'No leads'),
          const SizedBox(width: 20),
          _legendDot(const Color(0xFF00CEC8), 'Has leads'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCountyInfoBar(AppProvider provider, List<StateData> states) {
    County? county;
    StateData? state;
    for (final s in states) {
      for (final c in s.counties) {
        if (c.id == _selectedCountyId) {
          county = c;
          state = s;
          break;
        }
      }
      if (county != null) break;
    }
    if (county == null || state == null) return const SizedBox.shrink();

    final assignee = county.assignedTo != null
        ? provider.users.cast<AppUser?>().firstWhere(
            (u) => u!.id == county!.assignedTo, orElse: () => null)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.gold, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(state.code,
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(county.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  assignee != null
                      ? 'Assigned: ${assignee.name}'
                      : 'Unassigned',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: county.leadCount > 0
                  ? AppColors.accent.withAlpha(40)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${county.leadCount} leads',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: county.leadCount > 0
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.gold),
            onPressed: () => _showEditDialog(provider, state!, county!),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints,
      List<StateData> states, AppProvider provider) {
    final matrix = _transformCtrl.value;
    final inverseMatrix = Matrix4.tryInvert(matrix);
    if (inverseMatrix == null) return;

    final localPoint = MatrixUtils.transformPoint(
        inverseMatrix, details.localPosition);
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final padding = 16.0;
    final drawW = w - padding * 2;
    final drawH = h - padding * 2;

    String? closestId;
    double closestDist = double.infinity;

    for (final state in states) {
      final positions = _getPositions(state.code);
      final stateOffset = _getStateDrawOffset(
          state.code, _filterState, drawW, drawH, padding);

      for (final county in state.counties) {
        final pos = positions[county.name];
        if (pos == null) continue;

        final cx = stateOffset.dx + pos.x * stateOffset.width;
        final cy = stateOffset.dy + pos.y * stateOffset.height;

        final dist = (localPoint - Offset(cx, cy)).distance;
        if (dist < closestDist && dist < 25) {
          closestDist = dist;
          closestId = county.id;
        }
      }
    }

    setState(() => _selectedCountyId = closestId);
  }

  _StateDrawRect _getStateDrawOffset(
      String code, String? filter, double w, double h, double padding) {
    if (filter != null) {
      return _StateDrawRect(padding, padding, w, h);
    }
    switch (code) {
      case 'KY':
        return _StateDrawRect(padding, padding, w, h * 0.35);
      case 'TN':
        return _StateDrawRect(padding, padding + h * 0.35, w, h * 0.30);
      case 'WV':
        return _StateDrawRect(w * 0.55 + padding, padding, w * 0.45, h * 0.40);
      default:
        return _StateDrawRect(padding, padding, w, h);
    }
  }

  void _showEditDialog(AppProvider provider, StateData state, County county) {
    final leadCtrl = TextEditingController(
        text: county.leadCount > 0 ? county.leadCount.toString() : '');
    String? selectedUserId = county.assignedTo;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(state.code,
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(county.name),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: leadCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lead Count'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned',
                            style: TextStyle(color: AppColors.textSecondary))),
                    ...provider.users.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.role.name})'),
                        )),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedUserId = v),
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
                final count = int.tryParse(leadCtrl.text) ?? 0;
                provider.updateCountyLeads(state.code, county.name, count);
                provider.assignCounty(state.code, county.name, selectedUserId);
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateDrawRect {
  final double dx, dy, width, height;
  const _StateDrawRect(this.dx, this.dy, this.width, this.height);
}

class _GeoMapPainter extends CustomPainter {
  final List<StateData> states;
  final Map<String, CountyPosition> Function(String) getPositions;
  final AppProvider provider;
  final String? selectedCountyId;
  final String? filterState;

  _GeoMapPainter({
    required this.states,
    required this.getPositions,
    required this.provider,
    this.selectedCountyId,
    this.filterState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 16.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    for (final state in states) {
      final rect = _getRect(state.code, w, h, padding);
      _drawStateRegion(canvas, state, rect);
      _drawCounties(canvas, state, rect);
    }
  }

  _StateDrawRect _getRect(String code, double w, double h, double padding) {
    if (filterState != null) {
      return _StateDrawRect(padding, padding, w, h);
    }
    switch (code) {
      case 'KY':
        return _StateDrawRect(padding, padding, w, h * 0.35);
      case 'TN':
        return _StateDrawRect(padding, padding + h * 0.35, w, h * 0.30);
      case 'WV':
        return _StateDrawRect(w * 0.55 + padding, padding, w * 0.45, h * 0.40);
      default:
        return _StateDrawRect(padding, padding, w, h);
    }
  }

  void _drawStateRegion(Canvas canvas, StateData state, _StateDrawRect rect) {
    final bgPaint = Paint()
      ..color = AppColors.secondary.withAlpha(60)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.countyBorder.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.dx, rect.dy, rect.width, rect.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    final labelPainter = TextPainter(
      text: TextSpan(
        text: state.name,
        style: TextStyle(
          color: AppColors.gold.withAlpha(80),
          fontSize: filterState != null ? 28 : 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(rect.dx + 8, rect.dy + 4));
  }

  void _drawCounties(Canvas canvas, StateData state, _StateDrawRect rect) {
    final positions = getPositions(state.code);
    final isSingleState = filterState != null;
    final dotRadius = isSingleState ? 14.0 : 8.0;
    final fontSize = isSingleState ? 8.0 : 6.0;
    final countFontSize = isSingleState ? 9.0 : 7.0;

    for (final county in state.counties) {
      final pos = positions[county.name];
      if (pos == null) continue;

      final cx = rect.dx + pos.x * rect.width;
      final cy = rect.dy + pos.y * rect.height;
      final isSelected = county.id == selectedCountyId;

      final fillColor = _getHeatColor(county.leadCount);
      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cx, cy), dotRadius, paint);

      if (isSelected) {
        canvas.drawCircle(
          Offset(cx, cy),
          dotRadius + 3,
          Paint()
            ..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      if (county.leadCount > 0) {
        canvas.drawCircle(
          Offset(cx, cy),
          dotRadius + 1,
          Paint()
            ..color = AppColors.gold.withAlpha(100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      final namePainter = TextPainter(
        text: TextSpan(
          text: isSingleState ? county.name : _abbreviate(county.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      namePainter.paint(
        canvas,
        Offset(cx - namePainter.width / 2, cy - namePainter.height / 2 - (county.leadCount > 0 ? 4 : 0)),
      );

      if (county.leadCount > 0) {
        final countPainter = TextPainter(
          text: TextSpan(
            text: '${county.leadCount}',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        countPainter.paint(
          canvas,
          Offset(cx - countPainter.width / 2, cy + 2),
        );
      }

      if (isSingleState && county.assignedTo != null) {
        final user = provider.users.cast<AppUser?>().firstWhere(
            (u) => u!.id == county.assignedTo, orElse: () => null);
        if (user != null) {
          final assignPainter = TextPainter(
            text: TextSpan(
              text: user.name.split(' ').first,
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(200),
                fontSize: 6,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout();
          assignPainter.paint(
            canvas,
            Offset(cx - assignPainter.width / 2, cy + dotRadius + 2),
          );
        }
      }
    }
  }

  String _abbreviate(String name) {
    if (name.length <= 4) return name;
    return '${name.substring(0, 3)}.';
  }

  Color _getHeatColor(int leads) {
    if (leads == 0) return AppColors.countyFill;
    return const Color(0xFF00CEC8);
  }

  @override
  bool shouldRepaint(covariant _GeoMapPainter old) => true;
}
