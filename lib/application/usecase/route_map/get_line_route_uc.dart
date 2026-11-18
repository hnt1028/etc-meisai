import 'package:etc_meisai/application/dto/line_route_dto.dart';
import 'package:etc_meisai/application/dto/route_place_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/route_map/implied_entrance.dart';
import 'package:etc_meisai/application/usecase/route_map/route_runs.dart';

/// Finds what the statement detail screen draws for one statement line.
/// Design: PRC-012.
class GetLineRouteUC {
  const GetLineRouteUC({
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
  });

  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;

  Future<LineRouteDTO> execute(StatementLineDTO line) async {
    final lookup = IcLookup(
      points: await icMaster.findAll(),
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );

    final entranceName = line.entranceIc;
    // A blank entrance of a road with two ICs is the other end.
    final impliedName = entranceName == null
        ? impliedEntranceNameOf(line.exitIc, lookup)
        : null;
    // The same IC name is one marker, and is listed once. The implied entrance
    // is a marker too, but it is never reported as unlocated: the user did not
    // write it.
    final names = [
      ?entranceName,
      ?impliedName,
      if (line.exitIc != entranceName) line.exitIc,
    ];
    final places = <RoutePlaceDTO>[];
    final unlocated = <String>[];
    for (final name in names) {
      final place = lookup.placeOf(name);
      if (place == null) {
        if (name != impliedName) unlocated.add(name);
        continue;
      }
      places.add(
        RoutePlaceDTO(
          icName: name,
          latitude: place.latitude,
          longitude: place.longitude,
          source: place.source,
          approximate: place.approximate,
          routeNames: List.unmodifiable(place.point?.routeNames ?? const []),
          lineCount: 1,
        ),
      );
    }

    final entrance = entranceName == null ? null : lookup.placeOf(entranceName);
    final exit = lookup.placeOf(line.exitIc);
    final drawnFromName = entranceName ?? impliedName;
    final drawnFrom =
        entrance ?? (impliedName == null ? null : lookup.placeOf(impliedName));
    final distance = IcDistance(await icMaster.findLinks());
    final segment = drawnFromName != null && drawnFrom != null && exit != null
        ? RouteSegmentDTO(
            line: line,
            fromIcName: drawnFromName,
            toIcName: line.exitIc,
            fromLatitude: drawnFrom.latitude,
            fromLongitude: drawnFrom.longitude,
            toLatitude: exit.latitude,
            toLongitude: exit.longitude,
            via: [
              for (final point in routeVerticesOf(
                entrance: drawnFrom,
                exit: exit,
                lookup: lookup,
                distance: distance,
              ))
                RouteVertexDTO(
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
            ],
            runs: routeRunsOf(
              entrance: drawnFrom,
              exit: exit,
              lineRouteNames: lookup.routeNamesOf(drawnFromName, line.exitIc),
              lookup: lookup,
              distance: distance,
            ),
          )
        : null;

    return LineRouteDTO(
      segment: segment,
      places: places,
      unlocatedIcNames: unlocated,
      meters: lineMeters(
        entranceIc: entranceName,
        exitIc: line.exitIc,
        lookup: lookup,
        distance: distance,
      ),
    );
  }
}
