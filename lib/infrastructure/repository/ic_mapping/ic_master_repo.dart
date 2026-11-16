import 'dart:convert';

import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// Reads the IC master, which is `assets/ic_master.json` (see docs/route-map.md).
class IcMasterRepo implements IcMasterIF {
  IcMasterRepo({required this.loadJson});

  /// Gives the text of the JSON file. The app passes a function that reads the
  /// asset (see lib/main.dart).
  final Future<String> Function() loadJson;

  List<IcPointEntity>? _points;
  List<IcLinkEntity>? _links;

  Future<void> _load() async {
    if (_points != null) return;
    final json = jsonDecode(await loadJson()) as Map;
    _points = _parsePoints(json);
    _links = _parseLinks(json);
  }

  @override
  Future<List<IcPointEntity>> findAll() async {
    await _load();
    return _points!;
  }

  @override
  Future<List<IcLinkEntity>> findLinks() async {
    await _load();
    return _links!;
  }

  /// `[lat, lon, lat, lon, ...]` to points.
  static List<GeoPointEntity> _parseShape(List flat) {
    return List.unmodifiable([
      for (var i = 0; i + 1 < flat.length; i += 2)
        GeoPointEntity(
          latitude: (flat[i] as num).toDouble(),
          longitude: (flat[i + 1] as num).toDouble(),
        ),
    ]);
  }

  static List<IcLinkEntity> _parseLinks(Map json) {
    final links = (json['links'] as List?) ?? const [];
    return List.unmodifiable([
      for (final l in links.cast<List>())
        IcLinkEntity(
          fromId: l[0] as String,
          toId: l[1] as String,
          meters: l[2] as int,
          shape: l.length > 3 ? _parseShape(l[3] as List) : const [],
        ),
    ]);
  }

  static List<IcPointEntity> _parsePoints(Map json) {
    final points = json['points'] as List;
    return List.unmodifiable([
      for (final p in points.cast<Map<String, Object?>>())
        IcPointEntity(
          id: p['id'] as String,
          name: p['name'] as String,
          kind: IcKindValue.fromCode(p['kind'] as int),
          latitude: (p['lat'] as num).toDouble(),
          longitude: (p['lon'] as num).toDouble(),
          routeNames: List.unmodifiable((p['routes'] as List).cast<String>()),
        ),
    ]);
  }
}
