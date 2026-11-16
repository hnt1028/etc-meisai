import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:flutter/material.dart';

/// The color of a line on the road of an operator (docs/route-map.md, "線の
/// 色"). The user does not choose it. One color for each operator of
/// [knownOperators], as a Material color: its darker shade on a light theme,
/// its lighter shade on a dark theme, so that it can be seen on the map.
const _colors = <String, MaterialColor>{
  'NEXCO東日本': Colors.blue,
  'NEXCO中日本': Colors.green,
  'NEXCO西日本': Colors.orange,
  '首都高速道路': Colors.purple,
  '阪神高速道路': Colors.red,
  '名古屋高速道路公社': Colors.teal,
  '福岡北九州高速道路公社': Colors.brown,
  '広島高速道路公社': Colors.pink,
  '本州四国連絡高速道路': Colors.indigo,
};

/// The color of the line of [operator]. The color of the neutral outline for
/// an operator that is not known.
Color operatorLineColor(BuildContext context, String operator) {
  final theme = Theme.of(context);
  final color = _colors[operator];
  if (color == null) return theme.colorScheme.outline.withValues(alpha: 0.8);
  final dark = theme.brightness == Brightness.dark;
  return (dark ? color.shade300 : color.shade700).withValues(alpha: 0.85);
}

/// The parts of a line to draw, each in the color of its operator. A line
/// without parts is drawn as it is, from the entrance, through the points
/// between, to the exit, in one part.
List<RouteRunDTO> segmentRuns(RouteSegmentDTO segment) {
  if (segment.runs.isNotEmpty) return segment.runs;
  return [
    RouteRunDTO(
      operator: unknownOperator,
      points: [
        RouteVertexDTO(
          latitude: segment.fromLatitude,
          longitude: segment.fromLongitude,
        ),
        ...segment.via,
        RouteVertexDTO(
          latitude: segment.toLatitude,
          longitude: segment.toLongitude,
        ),
      ],
    ),
  ];
}

/// The color of a part of a line: of its operator, or, when the operator is
/// not known, the main color of the theme as before.
Color runColor(BuildContext context, RouteRunDTO run, ColorScheme scheme) {
  if (run.operator == unknownOperator) {
    return scheme.primary.withValues(alpha: 0.7);
  }
  return operatorLineColor(context, run.operator);
}
