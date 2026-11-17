import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_route_supplements.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// The operators of the roads at one point, by its routes.
List<String> _operatorsAt(IcPointEntity point) {
  final names = point.routeNames.isNotEmpty
      ? point.routeNames
      : [?routeSupplementOf(point.name)];
  return {for (final name in names) ?routeOperatorOf(name)}.toList();
}

/// The operator of the road between two points next to each other: the one
/// both points have. When they have none in common (a junction between two
/// operators), the one of the first point, so the color changes at the second
/// point. [unknownOperator] when neither is known.
String _operatorBetween(IcPointEntity a, IcPointEntity b) {
  final onA = _operatorsAt(a), onB = _operatorsAt(b);
  for (final operator in onA) {
    if (onB.contains(operator)) return operator;
  }
  if (onA.isNotEmpty) return onA.first;
  if (onB.isNotEmpty) return onB.first;
  return unknownOperator;
}

RouteVertexDTO _vertex(double latitude, double longitude) =>
    RouteVertexDTO(latitude: latitude, longitude: longitude);

/// The line from [entrance] to [exit] cut into parts by the operator of the
/// road (docs/route-map.md, "線の色"). One part when the line is straight
/// (no way over the links, or a position the user chose): the operator of
/// [lineRouteNames] when they have one, else [unknownOperator].
List<RouteRunDTO> routeRunsOf({
  required IcPlace entrance,
  required IcPlace exit,
  required List<String> lineRouteNames,
  required IcLookup lookup,
  required IcDistance distance,
}) {
  final start = _vertex(entrance.latitude, entrance.longitude);
  final end = _vertex(exit.latitude, exit.longitude);
  final from = entrance.point, to = exit.point;
  final route = from == null || to == null
      ? null
      : distance.roadRouteBetween(from, to);
  final ids = route?.pointIds ?? const <String>[];
  if (ids.length < 2) {
    final operator = operatorOfRoutes(lineRouteNames);
    return [
      RouteRunDTO(
        operator: operator == multipleOperators ? unknownOperator : operator,
        points: [start, end],
      ),
    ];
  }

  final runs = <RouteRunDTO>[];
  var operator = '';
  var points = <RouteVertexDTO>[start];
  for (var i = 0; i + 1 < ids.length; i++) {
    final a = lookup.pointOf(ids[i]), b = lookup.pointOf(ids[i + 1]);
    final here = a == null || b == null
        ? unknownOperator
        : _operatorBetween(a, b);
    if (i > 0 && here != operator) {
      runs.add(RouteRunDTO(operator: operator, points: points));
      points = [points.last];
    }
    operator = here;
    for (final p in distance.shapeBetween(ids[i], ids[i + 1])) {
      points.add(_vertex(p.latitude, p.longitude));
    }
    points.add(
      i + 2 < ids.length && b != null ? _vertex(b.latitude, b.longitude) : end,
    );
  }
  runs.add(RouteRunDTO(operator: operator, points: points));
  return runs;
}
