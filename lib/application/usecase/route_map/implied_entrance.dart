import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';

/// A short road whose blank entrance is known from the exit. The table is in
/// docs/route-map.md ("入口が空欄の明細行の線"): change both together.
class _ImpliedEntrance {
  const _ImpliedEntrance({
    required this.exit,
    required this.entrance,
    this.routeName,
    this.bothWays = false,
  });

  /// The exit IC (the name of the point of the master).
  final String exit;

  /// The IC that is the entrance when the entrance is blank.
  final String entrance;

  /// The route the exit must be on, when the master knows it.
  final String? routeName;

  /// True when the same holds with exit and entrance swapped.
  final bool bothWays;
}

const _rules = [
  _ImpliedEntrance(
    exit: '平湯',
    entrance: '中ノ湯',
    routeName: '安房峠道路',
    bothWays: true,
  ),
  // The Tokyo Bay Aqua-Line starts at this junction (a point of N06; the road
  // is from OpenStreetMap). The exit may be written with the number of the
  // toll gate ("木更津金田第一"), which the lookup completes.
  _ImpliedEntrance(exit: '木更津金田', entrance: '浮島/川崎浮島JCT'),
];

/// The IC name that is the entrance of a line with a blank entrance and the
/// exit [exitIc], or null when the exit is not in the table. The exit must be
/// a point of the master.
String? impliedEntranceNameOf(String exitIc, IcLookup lookup) {
  final point = lookup.resolve(exitIc).point;
  if (point == null) return null;
  for (final rule in _rules) {
    final onRoute =
        rule.routeName == null || point.routeNames.contains(rule.routeName);
    if (!onRoute) continue;
    if (point.name == rule.exit) return rule.entrance;
    if (rule.bothWays && point.name == rule.entrance) return rule.exit;
  }
  return null;
}
