import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';

/// The result of [IcLookup.resolve].
class IcResolution {
  const IcResolution({
    required this.state,
    this.point,
    this.candidates = const [],
  });

  final IcMatchValue state;

  /// The point, when [state] is matched or registered.
  final IcPointEntity? point;

  /// The points that fit, when [state] is ambiguous.
  final List<IcPointEntity> candidates;
}

/// Ties the IC names of the CSV to the points of the IC master, and finds the
/// route names of a statement line. The rules are in docs/route-map.md.
class IcLookup {
  IcLookup({
    required Iterable<IcPointEntity> points,
    required Iterable<IcMappingEntity> mappings,
  }) : _mappings = {for (final m in mappings) m.icName: m.pointId} {
    for (final point in points) {
      _byId[point.id] = point;
      _byName.putIfAbsent(fold(point.name), () => []).add(point);
      final base = baseName(point.name);
      if (base.isNotEmpty) _byBase.putIfAbsent(base, () => []).add(point);
    }
  }

  final Map<String, String> _mappings;
  final Map<String, IcPointEntity> _byId = {};
  final Map<String, List<IcPointEntity>> _byName = {};
  final Map<String, List<IcPointEntity>> _byBase = {};
  final Map<String, IcResolution> _cache = {};

  /// The suffixes that differ between road operators (NEXCO writes IC, urban
  /// expressways write 出入口, 入口 or 出口). The longer ones come first.
  static const _suffixes = [
    'スマートic',
    'スマート',
    'sic',
    'jct',
    'ic',
    '出入口',
    '入口',
    '出口',
  ];

  /// Makes full-width letters, digits and symbols half-width, ignores the case
  /// and removes spaces, so that ＩＣ and IC are the same.
  static String fold(String name) {
    final buffer = StringBuffer();
    for (final unit in name.runes) {
      if (unit == 0x3000 || unit == 0x20) continue;
      if (unit >= 0xFF01 && unit <= 0xFF5E) {
        buffer.writeCharCode(unit - 0xFEE0);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString().toLowerCase();
  }

  /// [fold]ed [name] without its last suffix. A name that would become empty
  /// is kept as it is.
  static String baseName(String name) {
    final folded = fold(name);
    for (final suffix in _suffixes) {
      if (folded.endsWith(suffix)) {
        final base = folded.substring(0, folded.length - suffix.length);
        return base.isEmpty ? folded : base;
      }
    }
    return folded;
  }

  /// Finds the point of [icName]: a registered mapping first, then the name
  /// as it is, then the name without its suffix.
  IcResolution resolve(String icName) =>
      _cache.putIfAbsent(icName, () => _resolve(icName));

  IcResolution _resolve(String icName) {
    final registered = _byId[_mappings[icName]];
    if (registered != null) {
      return IcResolution(state: IcMatchValue.registered, point: registered);
    }
    final exact = _byName[fold(icName)] ?? const [];
    final candidates = exact.isNotEmpty
        ? exact
        : (_byBase[baseName(icName)] ?? const []);
    if (candidates.length == 1) {
      return IcResolution(state: IcMatchValue.matched, point: candidates.first);
    }
    if (candidates.isEmpty) {
      return const IcResolution(state: IcMatchValue.unknown);
    }
    return IcResolution(
      state: IcMatchValue.ambiguous,
      candidates: List.unmodifiable(candidates),
    );
  }

  /// Looks up an IC point by its id. Null when the master has no such point.
  IcPointEntity? pointOf(String id) => _byId[id];

  /// The routes of a statement line. The routes both ICs share, or, when they
  /// share none, the routes of both. With only one known point, its routes.
  /// Empty when no point is known.
  List<String> routeNamesOf(String? entranceIc, String exitIc) {
    final entrance = entranceIc == null ? null : resolve(entranceIc).point;
    final exit = resolve(exitIc).point;
    if (entrance == null && exit == null) return const [];
    if (entrance == null) return List.unmodifiable(exit!.routeNames);
    if (exit == null) return List.unmodifiable(entrance.routeNames);
    final common = entrance.routeNames.where(exit.routeNames.contains).toList();
    if (common.isNotEmpty) return List.unmodifiable(common);
    return List.unmodifiable({...entrance.routeNames, ...exit.routeNames});
  }
}
