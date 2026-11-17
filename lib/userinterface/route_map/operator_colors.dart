import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:flutter/material.dart';

/// The color of a line on the road of an operator (docs/route-map.md, "線の
/// 色"): the color of the logo of the operator. The user does not choose it.
/// One color for each operator of [knownOperators], as it is on a light theme;
/// on a dark theme it is made lighter, so that it can be seen on the map.
const _colors = <String, Color>{
  // NEXCO: the colors of the logos (ネクスコグリーン / オレンジ / ブルー).
  'NEXCO東日本': Color(0xFF2E9E4F),
  'NEXCO中日本': Color(0xFFF08300),
  'NEXCO西日本': Color(0xFF1E7FD8),
  // 首都高: read from the logo. 福岡北九州 (黄緑), 広島 (桃) and 本四 (藍): told
  // by the user; 本四 is deep, to be told from NEXCO西日本. 阪神 (a red) and
  // 名古屋 (a purple) are not the colors of their logos: those were too close
  // to other operators to be told apart on the map.
  '首都高速道路': Color(0xFF1490A8),
  '阪神高速道路': Color(0xFFD32F2F),
  '名古屋高速道路公社': Color(0xFF8E24AA),
  '福岡北九州高速道路公社': Color(0xFF8BC34A),
  '広島高速道路公社': Color(0xFFF06292),
  '本州四国連絡高速道路': Color(0xFF1A2A80),
};

/// The color of the line of [operator]. The color of the neutral outline for
/// an operator that is not known.
Color operatorLineColor(BuildContext context, String operator) {
  final theme = Theme.of(context);
  final color = _colors[operator];
  if (color == null) return theme.colorScheme.outline.withValues(alpha: 0.8);
  final dark = theme.brightness == Brightness.dark;
  final shown = dark ? Color.lerp(color, Colors.white, 0.4)! : color;
  return shown.withValues(alpha: 0.85);
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
