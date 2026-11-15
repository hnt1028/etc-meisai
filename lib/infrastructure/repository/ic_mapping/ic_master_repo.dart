import 'dart:convert';

import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// Reads the IC master, which is `assets/ic_master.json` (see docs/route-map.md).
class IcMasterRepo implements IcMasterIF {
  IcMasterRepo({required this.loadJson});

  /// Gives the text of the JSON file. The app passes a function that reads the
  /// asset (see lib/main.dart).
  final Future<String> Function() loadJson;

  List<IcPointEntity>? _points;

  @override
  Future<List<IcPointEntity>> findAll() async =>
      _points ??= _parse(await loadJson());

  static List<IcPointEntity> _parse(String json) {
    final points = (jsonDecode(json) as Map)['points'] as List;
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
