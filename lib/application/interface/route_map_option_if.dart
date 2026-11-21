import 'package:etc_meisai/domain/entity/route_map_option_entity.dart';

/// Stores the numbers the user set for the route map.
abstract interface class RouteMapOptionIF {
  /// Returns every number the user set.
  Future<List<RouteMapOptionEntity>> findAll();

  /// Stores [option], replacing the one of the same option.
  Future<void> save(RouteMapOptionEntity option);

  /// Deletes every setting.
  Future<void> deleteAll();
}
