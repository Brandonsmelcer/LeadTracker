import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../data/county_map_geometry.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'county_detail_dialog.dart';

Color heatColorForLeads(int leads) {
  if (leads == 0) return AppColors.countyFill;
  if (leads < 10) return const Color(0xFF1B5E20);
  if (leads < 50) return const Color(0xFF2E7D32);
  if (leads < 100) return const Color(0xFF388E3C);
  if (leads < 500) return const Color(0xFFFF8F00);
  return AppColors.accent;
}

class CountySvgMap extends StatefulWidget {
  final CountyMapLayer layer;
  final AppProvider provider;
  final String? searchQuery;
  final bool showLabels;

  const CountySvgMap({
    super.key,
    required this.layer,
    required this.provider,
    this.searchQuery,
    this.showLabels = true,
  });

  @override
  State<CountySvgMap> createState() => _CountySvgMapState();
}

class _CountySvgMapState extends State<CountySvgMap> {
  CountyPathShape? _hovered;
  final _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _transformController.value.getMaxScaleOnAxis();

  bool _matchesSearch(CountyPathShape shape) {
    final q = widget.searchQuery?.trim().toLowerCase();
    if (q == null || q.isEmpty) return true;
    return shape.countyName.toLowerCase().contains(q) ||
        shape.stateCode.toLowerCase().contains(q);
  }

  bool _shapeInScope(CountyPathShape shape) {
    final county = widget.provider.getCounty(shape.stateCode, shape.countyName);
    if (county == null) return false;
    if (widget.provider.currentUser.role == UserRole.admin) return true;
    return widget.provider.isCountyVisibleOnMap(county);
  }

  County? _countyFor(CountyPathShape shape) =>
      widget.provider.getCounty(shape.stateCode, shape.countyName);

  int _visibleLeads(CountyPathShape shape) {
    final county = _countyFor(shape);
    if (county == null) return 0;
    return widget.provider.mapVisibleLeadCount(county);
  }

  void _handleTap(Offset position) {
    for (final shape in widget.layer.counties.reversed) {
      if (!_matchesSearch(shape) || !_shapeInScope(shape)) continue;
      if (shape.path.contains(position)) {
        final county = _countyFor(shape);
        if (county != null) {
          CountyDetailDialog.show(
            context,
            county: county,
            stateCode: shape.stateCode,
            provider: widget.provider,
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDetailLabels = widget.showLabels && _currentScale >= 1.2;
    final mapSize = Size(widget.layer.width, widget.layer.height);

    return SizedBox.expand(
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            () => EagerGestureRecognizer(),
            (_) {},
          ),
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
            (_) {},
          ),
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(),
            (_) {},
          ),
        },
        behavior: HitTestBehavior.opaque,
        child: InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          clipBehavior: Clip.none,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 12.0,
          panEnabled: true,
          scaleEnabled: true,
          trackpadScrollCausesScale: true,
          onInteractionEnd: (_) => setState(() {}),
          child: MouseRegion(
            onHover: (e) {
              CountyPathShape? hit;
              for (final shape in widget.layer.counties.reversed) {
                if (shape.path.contains(e.localPosition)) {
                  hit = shape;
                  break;
                }
              }
              if (hit != _hovered) setState(() => _hovered = hit);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _handleTap(d.localPosition),
              child: SizedBox(
                width: mapSize.width,
                height: mapSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: mapSize,
                      painter: _CountyMapPainter(
                        layer: widget.layer,
                        provider: widget.provider,
                        searchQuery: widget.searchQuery,
                        hovered: _hovered,
                        getCounty: _countyFor,
                        matchesSearch: _matchesSearch,
                        shapeInScope: _shapeInScope,
                        visibleLeads: _visibleLeads,
                      ),
                    ),
                    if (widget.showLabels)
                      ...widget.layer.counties
                          .where((s) => _matchesSearch(s) && _shapeInScope(s))
                          .map((shape) {
                        final leads = _visibleLeads(shape);
                        final bounds = shape.bounds;
                        final labelWidth = bounds.width.clamp(36.0, 90.0);
                        final showName = showDetailLabels || bounds.width > 28;
                        final showCount = leads > 0;

                        if (!showName && !showCount) {
                          return const SizedBox.shrink();
                        }

                        return Positioned(
                          left: shape.centroid.dx - labelWidth / 2,
                          top: shape.centroid.dy - 14,
                          width: labelWidth,
                          child: IgnorePointer(
                            child: _CountyLabel(
                              name: showName ? shape.countyName : null,
                              leadCount: showCount ? leads : null,
                              compact: !showDetailLabels,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountyLabel extends StatelessWidget {
  final String? name;
  final int? leadCount;
  final bool compact;

  const _CountyLabel({
    this.name,
    this.leadCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 2 : 4, vertical: compact ? 1 : 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(170),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 7 : 9,
                fontWeight: FontWeight.w600,
                height: 1.1,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 2),
                ],
              ),
            ),
          ),
        if (leadCount != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(220),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gold.withAlpha(150)),
            ),
            child: Text(
              '$leadCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountyMapPainter extends CustomPainter {
  final CountyMapLayer layer;
  final AppProvider provider;
  final String? searchQuery;
  final CountyPathShape? hovered;
  final County? Function(CountyPathShape) getCounty;
  final bool Function(CountyPathShape) matchesSearch;
  final bool Function(CountyPathShape) shapeInScope;
  final int Function(CountyPathShape) visibleLeads;

  _CountyMapPainter({
    required this.layer,
    required this.provider,
    required this.searchQuery,
    required this.hovered,
    required this.getCounty,
    required this.matchesSearch,
    required this.shapeInScope,
    required this.visibleLeads,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    if (layer.stateCode == 'ALL') {
      double y = 0;
      const heights = {'TN': 206.0, 'KY': 357.0, 'WV': 719.0};
      final labels = {'TN': 'Tennessee', 'KY': 'Kentucky', 'WV': 'West Virginia'};
      for (final code in ['TN', 'KY', 'WV']) {
        y += heights[code]!;
        final dividerPaint = Paint()
          ..color = AppColors.gold.withAlpha(80)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), dividerPaint);
      }
      y = 0;
      for (final code in ['TN', 'KY', 'WV']) {
        final h = heights[code]!;
        _drawStateBanner(canvas, labels[code]!, Offset(8, y + 6));
        y += h;
      }
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.countyBorder
      ..strokeWidth = 0.75;

    for (final shape in layer.counties) {
      final county = getCounty(shape);
      final leads = county != null ? visibleLeads(shape) : 0;
      final inScope = shapeInScope(shape);
      final dimmed = !matchesSearch(shape) || !inScope;
      final isHovered = hovered == shape;

      fillPaint.color = dimmed
          ? AppColors.countyFill.withAlpha(60)
          : heatColorForLeads(leads);

      canvas.drawPath(shape.path, fillPaint);
      canvas.drawPath(shape.path, strokePaint);

      if (isHovered && !dimmed) {
        canvas.drawPath(
          shape.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = AppColors.gold
            ..strokeWidth = 2.0,
        );
      }

      if (leads > 0 && !dimmed) {
        canvas.drawPath(
          shape.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = AppColors.gold.withAlpha(120)
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawStateBanner(Canvas canvas, String label, Offset position) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.left,
      ),
    )..addText(label.toUpperCase());
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 200));
    canvas.drawParagraph(paragraph, position);
  }

  @override
  bool shouldRepaint(covariant _CountyMapPainter old) =>
      old.searchQuery != searchQuery ||
      old.hovered != hovered ||
      old.provider.visibleTotalLeads != provider.visibleTotalLeads ||
      old.provider.visibleCoveredCounties != provider.visibleCoveredCounties;
}
