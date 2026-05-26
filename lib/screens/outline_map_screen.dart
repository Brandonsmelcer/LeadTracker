import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../data/county_boundaries.dart';

class OutlineMapScreen extends StatefulWidget {
  final String? filterStateCode;
  const OutlineMapScreen({super.key, this.filterStateCode});

  @override
  State<OutlineMapScreen> createState() => _OutlineMapScreenState();
}

class _OutlineMapScreenState extends State<OutlineMapScreen> {
  final TransformationController _transformCtrl = TransformationController();
  String? _selectedCountyKey;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final statesToShow = _filterState != null
            ? provider.states.where((s) => s.code == _filterState).toList()
            : provider.states;

        final totalLeads = statesToShow.fold(0, (sum, s) => sum + s.totalLeads);
        final totalCounties = statesToShow.fold(0, (sum, s) => sum + s.counties.length);
        final covered = statesToShow.fold(0, (sum, s) => sum + s.coveredCounties);

        final boundaries = _filterState != null
            ? countyBoundaries.where((b) => b.stateCode == _filterState).toList()
            : countyBoundaries;

        return Scaffold(
          appBar: AppBar(
            title: Text(_filterState != null
                ? '${statesToShow.first.name} Map'
                : 'All States Map'),
            actions: [
              if (widget.filterStateCode == null)
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() {
                    _filterState = v;
                    _selectedCountyKey = null;
                    _transformCtrl.value = Matrix4.identity();
                  }),
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
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStatsBar(totalLeads, totalCounties, covered),
              _buildLegend(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (details) => _handleTap(
                          details, constraints, boundaries, provider),
                      child: InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale: 0.5,
                        maxScale: 8.0,
                        boundaryMargin: const EdgeInsets.all(200),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _OutlineMapPainter(
                            boundaries: boundaries,
                            provider: provider,
                            selectedKey: _selectedCountyKey,
                            filterState: _filterState,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedCountyKey != null)
                _buildInfoBar(provider),
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
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.surface]),
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
          Container(width: 12, height: 12,
              decoration: BoxDecoration(
                  color: AppColors.countyFill,
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          const Text('No leads', style: TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 20),
          Container(width: 12, height: 12,
              decoration: BoxDecoration(
                  color: const Color(0xFF00CEC8),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          const Text('Has leads', style: TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints,
      List<CountyBoundary> boundaries, AppProvider provider) {
    final matrix = _transformCtrl.value;
    final inv = Matrix4.tryInvert(matrix);
    if (inv == null) return;
    final local = MatrixUtils.transformPoint(inv, details.localPosition);

    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final drawRect = _computeDrawRect(w, h);

    for (final b in boundaries) {
      final path = _buildCountyPath(b, drawRect);
      if (path.contains(local)) {
        setState(() => _selectedCountyKey = '${b.stateCode}_${b.name}');
        return;
      }
    }
    setState(() => _selectedCountyKey = null);
  }

  Path _buildCountyPath(CountyBoundary b, Rect drawRect) {
    final path = Path();
    final bounds = _filterState != null ? _getStateBounds(_filterState!) : null;

    for (final polygon in b.polygons) {
      for (final ring in polygon) {
        for (int i = 0; i < ring.length; i++) {
          final pt = ring[i];
          double px, py;
          if (bounds != null) {
            px = drawRect.left +
                ((pt[0] - bounds[0]) / (bounds[2] - bounds[0])) * drawRect.width;
            py = drawRect.top +
                ((pt[1] - bounds[1]) / (bounds[3] - bounds[1])) * drawRect.height;
          } else {
            px = drawRect.left + pt[0] * drawRect.width;
            py = drawRect.top + pt[1] * drawRect.height;
          }
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
      }
    }
    return path;
  }

  Rect _computeDrawRect(double w, double h) {
    const pad = 12.0;
    if (_filterState != null) {
      final bounds = _getStateBounds(_filterState!);
      final aspect = (bounds[2] - bounds[0]) / (bounds[3] - bounds[1]);
      final availW = w - pad * 2;
      final availH = h - pad * 2;
      double drawW, drawH;
      if (availW / availH > aspect) {
        drawH = availH;
        drawW = drawH * aspect;
      } else {
        drawW = availW;
        drawH = drawW / aspect;
      }
      return Rect.fromLTWH(
        pad + (availW - drawW) / 2, pad + (availH - drawH) / 2,
        drawW, drawH,
      );
    }
    return Rect.fromLTWH(pad, pad, w - pad * 2, h - pad * 2);
  }

  List<double> _getStateBounds(String code) {
    double minX = 1, maxX = 0, minY = 1, maxY = 0;
    for (final b in countyBoundaries.where((b) => b.stateCode == code)) {
      for (final poly in b.polygons) {
        for (final ring in poly) {
          for (final pt in ring) {
            if (pt[0] < minX) minX = pt[0];
            if (pt[0] > maxX) maxX = pt[0];
            if (pt[1] < minY) minY = pt[1];
            if (pt[1] > maxY) maxY = pt[1];
          }
        }
      }
    }
    return [minX, minY, maxX, maxY];
  }

  Widget _buildInfoBar(AppProvider provider) {
    if (_selectedCountyKey == null) return const SizedBox.shrink();
    final parts = _selectedCountyKey!.split('_');
    final stateCode = parts[0];
    final countyName = parts.sublist(1).join('_');

    County? county;
    StateData? state;
    try {
      state = provider.states.firstWhere((s) => s.code == stateCode);
      county = state.counties.firstWhere(
          (c) => c.name.toLowerCase() == countyName.toLowerCase());
    } catch (_) {
      return const SizedBox.shrink();
    }

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
              color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
            child: Text(stateCode, style: const TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(county.name, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                Text(assignee != null ? 'Assigned: ${assignee.name}' : 'Unassigned',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: county.leadCount > 0
                  ? AppColors.accent.withAlpha(40) : AppColors.surface,
              borderRadius: BorderRadius.circular(8)),
            child: Text('${county.leadCount} leads', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: county.leadCount > 0
                    ? AppColors.accent : AppColors.textSecondary)),
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

  void _showEditDialog(AppProvider provider, StateData state, County county) {
    final ctrl = TextEditingController(
        text: county.leadCount > 0 ? county.leadCount.toString() : '');
    String? userId = county.assignedTo;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text('${county.name}, ${state.code}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lead Count'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: userId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: [
                    const DropdownMenuItem(value: null,
                        child: Text('Unassigned',
                            style: TextStyle(color: AppColors.textSecondary))),
                    ...provider.users.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.role.name})'))),
                  ],
                  onChanged: (v) => setD(() => userId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                provider.updateCountyLeads(
                    state.code, county.name, int.tryParse(ctrl.text) ?? 0);
                provider.assignCounty(state.code, county.name, userId);
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

class _OutlineMapPainter extends CustomPainter {
  final List<CountyBoundary> boundaries;
  final AppProvider provider;
  final String? selectedKey;
  final String? filterState;

  _OutlineMapPainter({
    required this.boundaries,
    required this.provider,
    this.selectedKey,
    this.filterState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final Rect drawRect;
    if (filterState != null) {
      final bounds = _getStateBounds(filterState!);
      final aspect = (bounds[2] - bounds[0]) / (bounds[3] - bounds[1]);
      final availW = size.width - pad * 2;
      final availH = size.height - pad * 2;
      double drawW, drawH;
      if (availW / availH > aspect) {
        drawH = availH;
        drawW = drawH * aspect;
      } else {
        drawW = availW;
        drawH = drawW / aspect;
      }
      drawRect = Rect.fromLTWH(
        pad + (availW - drawW) / 2, pad + (availH - drawH) / 2,
        drawW, drawH,
      );
    } else {
      drawRect = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);
    }

    final bounds = filterState != null ? _getStateBounds(filterState!) : null;

    for (final b in boundaries) {
      final key = '${b.stateCode}_${b.name}';
      final county = _findCounty(b.stateCode, b.name);
      final isSelected = key == selectedKey;
      final leads = county?.leadCount ?? 0;
      final fillColor = _heatColor(leads);

      final path = Path();
      double cx = 0, cy = 0;
      int ptCount = 0;

      for (final polygon in b.polygons) {
        for (final ring in polygon) {
          for (int i = 0; i < ring.length; i++) {
            final pt = ring[i];
            double px, py;
            if (bounds != null) {
              px = drawRect.left +
                  ((pt[0] - bounds[0]) / (bounds[2] - bounds[0])) * drawRect.width;
              py = drawRect.top +
                  ((pt[1] - bounds[1]) / (bounds[3] - bounds[1])) * drawRect.height;
            } else {
              px = drawRect.left + pt[0] * drawRect.width;
              py = drawRect.top + pt[1] * drawRect.height;
            }
            if (i == 0) {
              path.moveTo(px, py);
            } else {
              path.lineTo(px, py);
            }
            cx += px;
            cy += py;
            ptCount++;
          }
          path.close();
        }
      }

      canvas.drawPath(path, Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill);

      canvas.drawPath(path, Paint()
        ..color = isSelected
            ? AppColors.gold
            : (leads > 0 ? AppColors.gold.withAlpha(120) : AppColors.countyBorder.withAlpha(120))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 0.8);

      if (ptCount > 0 && county != null) {
        final center = Offset(cx / ptCount, cy / ptCount);
        _drawLabel(canvas, center, county, isSelected, filterState != null);
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset center, County county,
      bool isSelected, bool isSingleState) {
    final nameFontSize = isSingleState ? 7.0 : 4.5;
    final countFontSize = isSingleState ? 8.0 : 5.5;
    final countOffset = isSingleState ? 5.0 : 3.0;

    final name = isSingleState
        ? (county.name.length > 8 ? '${county.name.substring(0, 7)}.' : county.name)
        : (county.name.length > 6 ? '${county.name.substring(0, 5)}.' : county.name);

    final namePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: isSelected ? AppColors.gold : Colors.white,
          fontSize: nameFontSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    namePainter.paint(canvas,
        Offset(center.dx - namePainter.width / 2,
            center.dy - namePainter.height / 2 - (county.leadCount > 0 ? countOffset : 0)));

    if (county.leadCount > 0) {
      final countPainter = TextPainter(
        text: TextSpan(
          text: '${county.leadCount}',
          style: TextStyle(
              color: Colors.white, fontSize: countFontSize, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      countPainter.paint(canvas,
          Offset(center.dx - countPainter.width / 2, center.dy + 1));
    }
  }

  County? _findCounty(String stateCode, String name) {
    try {
      final state = provider.states.firstWhere((s) => s.code == stateCode);
      return state.counties.firstWhere(
          (c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  List<double> _getStateBounds(String code) {
    double minX = 1, maxX = 0, minY = 1, maxY = 0;
    for (final b in countyBoundaries.where((b) => b.stateCode == code)) {
      for (final poly in b.polygons) {
        for (final ring in poly) {
          for (final pt in ring) {
            if (pt[0] < minX) minX = pt[0];
            if (pt[0] > maxX) maxX = pt[0];
            if (pt[1] < minY) minY = pt[1];
            if (pt[1] > maxY) maxY = pt[1];
          }
        }
      }
    }
    return [minX, minY, maxX, maxY];
  }

  Color _heatColor(int leads) {
    if (leads == 0) return AppColors.countyFill;
    return const Color(0xFF00CEC8);
  }

  @override
  bool shouldRepaint(covariant _OutlineMapPainter old) => true;
}
