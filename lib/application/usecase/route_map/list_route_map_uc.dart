import 'package:etc_meisai/application/dto/route_map_dto.dart';
import 'package:etc_meisai/application/dto/route_place_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/unlocated_ic_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/interface/vehicle_type_master_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/route_map/implied_entrance.dart';
import 'package:etc_meisai/application/usecase/statements/statement_filter.dart';

/// Lists what the route map draws. Design: PRC-009.
class ListRouteMapUC {
  const ListRouteMapUC({
    required this.statementLines,
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
    required this.vehicleTypes,
  });

  final StatementLineIF statementLines;
  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;
  final VehicleTypeMasterIF vehicleTypes;

  /// The conditions are the ones of the statement list ([from] and [to] are
  /// dates, and are included in the period).
  Future<RouteMapDTO> execute({
    DateTime? from,
    DateTime? to,
    int? vehicleNumber,
    String? cardNumberSuffix,
  }) async {
    final all = await statementLines.findAll();
    final divisions = await vehicleTypes.findAll();
    final lookup = IcLookup(
      points: await icMaster.findAll(),
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );
    final distance = IcDistance(await icMaster.findLinks());
    final lines = filterStatementLines(
      all,
      from: from,
      to: to,
      vehicleNumber: vehicleNumber,
      cardNumberSuffix: cardNumberSuffix,
    );

    final segments = <RouteSegmentDTO>[];
    var undrawn = 0;
    final lineCounts = <String, int>{};
    for (final line in lines) {
      final entranceName = line.entranceIc;
      final entrance = entranceName == null
          ? null
          : lookup.placeOf(entranceName);
      final exit = lookup.placeOf(line.exitIc);
      // A blank entrance of a road with two ICs is the other end.
      final impliedName = entranceName == null
          ? impliedEntranceNameOf(line.exitIc, lookup)
          : null;
      final drawnFromName = entranceName ?? impliedName;
      final drawnFrom =
          entrance ??
          (impliedName == null ? null : lookup.placeOf(impliedName));
      if (drawnFromName != null && drawnFrom != null && exit != null) {
        segments.add(
          RouteSegmentDTO(
            line: toStatementLineDTO(line, lookup, divisions),
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
          ),
        );
      } else {
        undrawn++;
      }
      // A line counts once for an IC name, even when both ICs have it.
      for (final name in {?entranceName, line.exitIc}) {
        lineCounts[name] = (lineCounts[name] ?? 0) + 1;
      }
    }

    final places = <RoutePlaceDTO>[];
    final unlocated = <UnlocatedIcDTO>[];
    lineCounts.forEach((name, count) {
      final place = lookup.placeOf(name);
      if (place == null) {
        unlocated.add(UnlocatedIcDTO(icName: name, lineCount: count));
      } else {
        places.add(
          RoutePlaceDTO(
            icName: name,
            latitude: place.latitude,
            longitude: place.longitude,
            source: place.source,
            approximate: place.approximate,
            routeNames: List.unmodifiable(place.point?.routeNames ?? const []),
            lineCount: count,
          ),
        );
      }
    });
    places.sort((a, b) => a.icName.compareTo(b.icName));
    unlocated.sort((a, b) {
      final byCount = b.lineCount.compareTo(a.lineCount);
      return byCount != 0 ? byCount : a.icName.compareTo(b.icName);
    });

    return RouteMapDTO(
      segments: segments,
      places: places,
      unlocated: unlocated,
      undrawnLineCount: undrawn,
      lineCount: lines.length,
      vehicleNumberChoices: vehicleNumberChoicesOf(all),
      cardNumberChoices: cardNumberChoicesOf(all),
    );
  }
}
