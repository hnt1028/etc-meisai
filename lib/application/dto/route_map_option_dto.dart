import 'package:etc_meisai/domain/value/route_map_option_value.dart';

/// The value of one number of the route map. Design: PRC-030.
class RouteMapOptionDTO {
  const RouteMapOptionDTO({required this.option, required this.value});

  final RouteMapOptionValue option;

  /// What the user set, or the default; always in the range of the option.
  final int value;
}
