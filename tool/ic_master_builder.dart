import 'dart:convert';
import 'dart:math' as math;

/// Makes the IC master from the GeoJSON of N06 (国土数値情報 高速道路時系列データ).
/// See docs/route-map.md.
///
/// [jointJson] is `N06-25_Joint.geojson` (points of ICs and junctions) and
/// [sectionJson] is `N06-25_HighwaySection.geojson` (lines of routes). Only the
/// features that still exist (the end of their period is 9999) are used.
Map<String, Object?> buildIcMaster({
  required String jointJson,
  required String sectionJson,
  required String source,
}) {
  final joints = _features(
    jointJson,
  ).where((f) => _props(f)['N06_014'] == 9999);
  final sections = [
    for (final f in _features(sectionJson))
      if (_props(f)['N06_003'] == 9999) _Section.of(f),
  ];

  final usedIds = <String>{};
  final points = <Map<String, Object?>>[];
  for (final f in joints) {
    final props = _props(f);
    final name = props['N06_018'] as String;
    final coordinates = (f['geometry'] as Map)['coordinates'] as List;
    final lon = (coordinates[0] as num).toDouble();
    final lat = (coordinates[1] as num).toDouble();

    // Several points can share one relation id, so the name is added.
    final base = '${props['N06_015']}:$name';
    var id = base;
    for (var n = 2; !usedIds.add(id); n++) {
      id = '$base-$n';
    }

    points.add({
      'id': id,
      'name': name,
      'kind': int.parse(props['N06_019'] as String),
      'lat': _round(lat),
      'lon': _round(lon),
      'routes': _routesNear(sections, lon, lat),
    });
  }
  points.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  return {'source': source, 'points': points};
}

/// A route name is kept when a line of the route passes this close to the
/// point. N06 puts every current IC on its routes, so this only has to absorb
/// small gaps.
const routeDistanceMeters = 50.0;

double _round(double value) => (value * 1e6).roundToDouble() / 1e6;

List<Map<String, Object?>> _features(String json) => [
  for (final f in (jsonDecode(json) as Map)['features'] as List)
    f as Map<String, Object?>,
];

Map<String, Object?> _props(Map<String, Object?> feature) =>
    feature['properties'] as Map<String, Object?>;

List<String> _routesNear(List<_Section> sections, double lon, double lat) {
  final found = <String, double>{};
  for (final section in sections) {
    if (!section.mayBeNear(lon, lat)) continue;
    final distance = section.distanceTo(lon, lat);
    if (distance > routeDistanceMeters) continue;
    final known = found[section.name];
    if (known == null || distance < known) found[section.name] = distance;
  }
  final names = found.keys.toList()
    ..sort((a, b) {
      final byDistance = found[a]!.compareTo(found[b]!);
      return byDistance != 0 ? byDistance : a.compareTo(b);
    });
  return names;
}

class _Section {
  _Section(this.name, this.lines) {
    var minLon = double.infinity, minLat = double.infinity;
    var maxLon = -double.infinity, maxLat = -double.infinity;
    for (final line in lines) {
      for (final c in line) {
        minLon = math.min(minLon, c[0]);
        maxLon = math.max(maxLon, c[0]);
        minLat = math.min(minLat, c[1]);
        maxLat = math.max(maxLat, c[1]);
      }
    }
    this.minLon = minLon;
    this.minLat = minLat;
    this.maxLon = maxLon;
    this.maxLat = maxLat;
  }

  factory _Section.of(Map<String, Object?> feature) {
    final geometry = feature['geometry'] as Map;
    final raw = geometry['coordinates'] as List;
    final lines = geometry['type'] == 'LineString' ? [raw] : raw;
    return _Section(_props(feature)['N06_007'] as String, [
      for (final line in lines)
        [
          for (final c in line as List)
            [(c[0] as num).toDouble(), (c[1] as num).toDouble()],
        ],
    ]);
  }

  final String name;
  final List<List<List<double>>> lines;
  late final double minLon, minLat, maxLon, maxLat;

  /// A cheap test with the bounding box, about 0.001 degrees wider.
  bool mayBeNear(double lon, double lat) =>
      lon >= minLon - 0.001 &&
      lon <= maxLon + 0.001 &&
      lat >= minLat - 0.001 &&
      lat <= maxLat + 0.001;

  /// The distance in meters from the point to the nearest part of the lines.
  double distanceTo(double lon, double lat) {
    final metersPerLon = 111320 * math.cos(lat * math.pi / 180);
    const metersPerLat = 110574.0;
    double x(double v) => v * metersPerLon;
    double y(double v) => v * metersPerLat;

    final px = x(lon), py = y(lat);
    var best = double.infinity;
    for (final line in lines) {
      for (var i = 0; i + 1 < line.length; i++) {
        final ax = x(line[i][0]), ay = y(line[i][1]);
        final bx = x(line[i + 1][0]), by = y(line[i + 1][1]);
        final dx = bx - ax, dy = by - ay;
        final lengthSquared = dx * dx + dy * dy;
        final t = lengthSquared == 0
            ? 0.0
            : (((px - ax) * dx + (py - ay) * dy) / lengthSquared).clamp(
                0.0,
                1.0,
              );
        final distance = math.sqrt(
          math.pow(px - (ax + t * dx), 2) + math.pow(py - (ay + t * dy), 2),
        );
        if (distance < best) best = distance;
      }
    }
    return best;
  }
}
