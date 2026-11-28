import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/route_map/operator_default_colors.dart';
import 'package:flutter/material.dart';

/// The color of the line of [operator], from [colors] (the colors in use,
/// PRC-021; the defaults while they are read). The color the user chose is
/// shown as it is. A default color is made lighter on a dark theme, so that it
/// can be seen on the map. The color of the neutral outline for an operator
/// that is not known.
Color operatorLineColor(
  BuildContext context,
  String operator,
  List<OperatorColorDTO>? colors,
) {
  final theme = Theme.of(context);
  OperatorColorDTO? dto;
  for (final c in colors ?? defaultOperatorColorDtos) {
    if (c.operatorName == operator) dto = c;
  }
  if (dto == null) return theme.colorScheme.outline.withValues(alpha: 0.8);
  final color = Color(dto.color);
  final dark = theme.brightness == Brightness.dark;
  final shown = dark && dto.isDefault
      ? Color.lerp(color, Colors.white, 0.4)!
      : color;
  return shown.withValues(alpha: 0.85);
}

/// The default colors as the colors in use, for the time they are read.
final defaultOperatorColorDtos = [
  for (final e in defaultOperatorColors.entries)
    OperatorColorDTO(operatorName: e.key, color: e.value, isDefault: true),
];

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
Color runColor(
  BuildContext context,
  RouteRunDTO run,
  ColorScheme scheme,
  List<OperatorColorDTO>? colors,
) {
  if (run.operator == unknownOperator) {
    return scheme.primary.withValues(alpha: 0.7);
  }
  return operatorLineColor(context, run.operator, colors);
}
