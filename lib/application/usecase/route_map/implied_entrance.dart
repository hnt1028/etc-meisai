import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';

/// A road that has only two ICs, so a blank entrance is the other end.
/// The table is in docs/route-map.md ("入口が空欄の明細行の線"): change both
/// together.
class _EndToEndRoad {
  const _EndToEndRoad(this.routeName, this.endA, this.endB);

  final String routeName;
  final String endA;
  final String endB;
}

const _roads = [_EndToEndRoad('安房峠道路', '中ノ湯', '平湯')];

/// The IC name that is the entrance of a line with a blank entrance and the
/// exit [exitIc], or null when the exit is not an end of such a road. The
/// exit must be a point of the master that is on the road.
String? impliedEntranceNameOf(String exitIc, IcLookup lookup) {
  final point = lookup.resolve(exitIc).point;
  if (point == null) return null;
  for (final road in _roads) {
    if (!point.routeNames.contains(road.routeName)) continue;
    if (point.name == road.endA) return road.endB;
    if (point.name == road.endB) return road.endA;
  }
  return null;
}
