import 'package:etc_meisai/application/interface/route_map_option_if.dart';
import 'package:etc_meisai/domain/entity/route_map_option_entity.dart';
import 'package:etc_meisai/domain/value/route_map_option_value.dart';

/// Stores a number the user set for the route map. Design: PRC-031.
class SaveRouteMapOptionUC {
  const SaveRouteMapOptionUC({required this.routeMapOptions});

  final RouteMapOptionIF routeMapOptions;

  /// [value] is brought into the range of the option.
  Future<void> execute({
    required RouteMapOptionValue option,
    required int value,
  }) {
    return routeMapOptions.save(
      RouteMapOptionEntity(
        optionCode: option.code,
        value: value.clamp(option.minimum, option.maximum),
      ),
    );
  }
}
