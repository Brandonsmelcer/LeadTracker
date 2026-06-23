import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

class CountyPathShape {
  final String stateCode;
  final String countyName;
  final String pathId;
  final Path path;
  final Offset centroid;
  final Rect bounds;

  const CountyPathShape({
    required this.stateCode,
    required this.countyName,
    required this.pathId,
    required this.path,
    required this.centroid,
    required this.bounds,
  });
}

class CountyMapLayer {
  final String stateCode;
  final String stateName;
  final double width;
  final double height;
  final double yOffset;
  final List<CountyPathShape> counties;

  const CountyMapLayer({
    required this.stateCode,
    required this.stateName,
    required this.width,
    required this.height,
    required this.yOffset,
    required this.counties,
  });

  /// Precise SVG path hit-test: only [Path.contains] matches (not bounds),
  /// preferring the smallest county when paths overlap at borders.
  CountyPathShape? hitTestAt(
    Offset point, {
    required bool Function(CountyPathShape shape) include,
  }) {
    CountyPathShape? best;
    var smallestArea = double.infinity;

    for (final shape in counties) {
      if (!include(shape)) continue;
      if (!shape.path.contains(point)) continue;

      final area = shape.bounds.width * shape.bounds.height;
      if (area < smallestArea) {
        smallestArea = area;
        best = shape;
      }
    }

    return best;
  }
}

class CountyMapGeometry {
  final Map<String, CountyMapLayer> _layers;
  final CountyMapLayer combined;

  CountyMapGeometry._({
    required Map<String, CountyMapLayer> layers,
    required this.combined,
  }) : _layers = layers;

  static CountyMapGeometry? _instance;

  static Future<CountyMapGeometry> load() async {
    if (_instance != null) return _instance!;
    final raw =
        await rootBundle.loadString('assets/maps/county_paths.json');
    _instance = CountyMapGeometry._parse(json.decode(raw) as Map<String, dynamic>);
    return _instance!;
  }

  CountyMapLayer? layerFor(String stateCode) => _layers[stateCode];

  static CountyMapGeometry _parse(Map<String, dynamic> data) {
    const stateNames = {
      'TN': 'Tennessee',
      'KY': 'Kentucky',
      'WV': 'West Virginia',
    };

    final layers = <String, CountyMapLayer>{};

    for (final code in ['TN', 'KY', 'WV']) {
      final stateData = data[code] as Map<String, dynamic>;
      final viewBox = (stateData['viewBox'] as List).cast<num>();
      final width = viewBox[2].toDouble();
      final height = viewBox[3].toDouble();
      final countiesJson = stateData['counties'] as Map<String, dynamic>;

      final counties = <CountyPathShape>[];
      for (final entry in countiesJson.entries) {
        final name = entry.key;
        final d = entry.value as String;
        final path = parseSvgPathData(d);
        final bounds = path.getBounds();
        counties.add(CountyPathShape(
          stateCode: code,
          countyName: name,
          pathId: name,
          path: path,
          bounds: bounds,
          centroid: bounds.center,
        ));
      }

      layers[code] = CountyMapLayer(
        stateCode: code,
        stateName: stateNames[code]!,
        width: width,
        height: height,
        yOffset: 0,
        counties: counties,
      );
    }

    double combinedYOffset = 0;
    final combinedCounties = <CountyPathShape>[];
    for (final code in ['TN', 'KY', 'WV']) {
      final layer = layers[code]!;
      for (final county in layer.counties) {
        combinedCounties.add(CountyPathShape(
          stateCode: county.stateCode,
          countyName: county.countyName,
          pathId: county.pathId,
          path: county.path.shift(Offset(0, combinedYOffset)),
          bounds: county.bounds.shift(Offset(0, combinedYOffset)),
          centroid: county.centroid + Offset(0, combinedYOffset),
        ));
      }
      combinedYOffset += layer.height;
    }

    final combined = CountyMapLayer(
      stateCode: 'ALL',
      stateName: 'Combined 3-State',
      width: 810,
      height: combinedYOffset,
      yOffset: 0,
      counties: combinedCounties,
    );

    return CountyMapGeometry._(layers: layers, combined: combined);
  }
}
