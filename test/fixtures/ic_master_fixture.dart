import 'dart:convert';

/// A fictional IC master that fits StatementFixture: the IC names of its CSV
/// without their suffix. テスト北 has two points, so it needs the user's choice.
String icMasterFixtureJson() => jsonEncode({
  'source': 'fictional',
  'points': [
    _point('T-N1', 'テスト北', 35.1, 139.1, ['テスト自動車道']),
    _point('T-N2', 'テスト北', 36.2, 140.2, ['テスト高速道路']),
    _point('T-E', 'テスト東', 35.2, 139.2, ['テスト自動車道']),
    _point('T-W', 'テスト西', 35.3, 139.3, ['テスト自動車道', 'テスト都市高速']),
    _point('T-S', 'テスト南', 35.4, 139.4, ['テスト自動車道']),
  ],
});

Map<String, Object?> _point(
  String id,
  String name,
  double lat,
  double lon,
  List<String> routes,
) => {
  'id': id,
  'name': name,
  'kind': 1,
  'lat': lat,
  'lon': lon,
  'routes': routes,
};
