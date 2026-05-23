import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_lead_map/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled county GeoJSON contains only WV, TN, and KY counties',
    () async {
      final rawGeoJson = await rootBundle.loadString(
        'assets/counties_wv_tn_ky.geojson',
      );
      final counties = CountyFeatureParser.parse(rawGeoJson);

      expect(counties, hasLength(270));
      expect(
        counties.where((county) => county.stateCode == 'WV'),
        hasLength(55),
      );
      expect(
        counties.where((county) => county.stateCode == 'TN'),
        hasLength(95),
      );
      expect(
        counties.where((county) => county.stateCode == 'KY'),
        hasLength(120),
      );
      expect(counties.map((county) => county.stateCode).toSet(), {
        'WV',
        'TN',
        'KY',
      });
      expect(counties.every((county) => county.fips.length == 5), isTrue);
    },
  );

  test('lead records serialize cleanly for local storage', () {
    const record = LeadRecord(
      owner: 'Avery Carter',
      leadCount: 42,
      notes: 'Medicare supplement cross-sell list.',
      priority: true,
    );

    final decoded = LeadRecord.fromJson(record.toJson());

    expect(decoded.owner, 'Avery Carter');
    expect(decoded.leadCount, 42);
    expect(decoded.notes, 'Medicare supplement cross-sell list.');
    expect(decoded.priority, isTrue);
    expect(decoded.hasActivity, isTrue);
  });
}
