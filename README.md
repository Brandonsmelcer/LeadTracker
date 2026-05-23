# Life Lead Map

A Flutter app for life insurance teams that need a polished, offline-friendly county lead map for West Virginia, Tennessee, and Kentucky.

## What it does

- Draws a flat vector-style FIPS county map from bundled GeoJSON data.
- Supports a merged WV/TN/KY territory view plus individual state views from a dropdown.
- Shows county names directly on the map, with a toggle for cleaner viewing.
- Lets users tap a county or list item to edit lead owner, lead count, priority status, and notes.
- Persists county lead data locally on Android and iOS with `shared_preferences`.

## Data scope

The app intentionally includes only:

- West Virginia: 55 counties
- Tennessee: 95 counties
- Kentucky: 120 counties

The bundled county features are stored at `assets/counties_wv_tn_ky.geojson` and keyed by 5-digit FIPS code.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```
