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
    // The same IC name is one marker, and is listed once.
    final names = [?entranceName, if (line.exitIc != entranceName) line.exitIc];
    final places = <RoutePlaceDTO>[];
    final unlocated = <String>[];
    for (final name in names) {
      final place = lookup.placeOf(name);
      if (place == null) {
        unlocated.add(name);
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
    final segment = entranceName != null && entrance != null && exit != null
        ? RouteSegmentDTO(
            line: line,
            fromIcName: entranceName,
            toIcName: line.exitIc,
            fromLatitude: entrance.latitude,
            fromLongitude: entrance.longitude,
            toLatitude: exit.latitude,
            toLongitude: exit.longitude,
            via: [
              for (final point in viaPointsOf(
                entrance: entrance,
                exit: exit,
                lookup: lookup,
                distance: IcDistance(await icMaster.findLinks()),
              ))
                RouteVertexDTO(
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
            ],
          )
        : null;

    return LineRouteDTO(
      segment: segment,
      places: places,
      unlocatedIcNames: unlocated,
    );
  }
}
