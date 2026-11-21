import 'package:etc_meisai/application/dto/route_map_option_dto.dart';
import 'package:etc_meisai/application/interface/route_map_option_if.dart';
import 'package:etc_meisai/domain/value/route_map_option_value.dart';

/// Lists the numbers of the route map: what the user set, or else the
/// default. Design: PRC-030.
class ListRouteMapOptionsUC {
  const ListRouteMapOptionsUC({required this.routeMapOptions});

  final RouteMapOptionIF routeMapOptions;

  /// In the order of [RouteMapOptionValue.values]. A value out of the range
  /// (a backup written by hand) is brought into it.
  Future<List<RouteMapOptionDTO>> execute() async {
    final chosen = {
      for (final o in await routeMapOptions.findAll()) o.optionCode: o.value,
    };
    return [
      for (final option in RouteMapOptionValue.values)
        RouteMapOptionDTO(
          option: option,
          value: (chosen[option.code] ?? option.defaultValue).clamp(
            option.minimum,
            option.maximum,
          ),
        ),
    ];
  }
}
