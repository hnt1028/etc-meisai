import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';

/// Routes the IC master (N06) does not have, found by the start of the IC name.
/// The table is in docs/route-map.md ("路線の補足"): change both together.
const _supplements = <String, String>{
  '木更津金田': '東京湾アクアライン',
  'アクア': '東京湾アクアライン',
  '海ほたる': '東京湾アクアライン',
};

/// The route of an IC name the master does not have, or null. It says nothing
/// about the position of the IC.
String? routeSupplementOf(String icName) {
  final folded = IcLookup.fold(icName);
  for (final entry in _supplements.entries) {
    if (folded.startsWith(IcLookup.fold(entry.key))) return entry.value;
  }
  return null;
}
