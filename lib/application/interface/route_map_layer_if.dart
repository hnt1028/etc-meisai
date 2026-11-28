import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';

/// Stores what the user chose to show on the route map.
abstract interface class RouteMapLayerIF {
  /// Returns every layer the user chose.
  Future<List<RouteMapLayerEntity>> findAll();

  /// Stores [layer], replacing the one of the same layer.
  Future<void> save(RouteMapLayerEntity layer);

  /// Deletes every choice.
  Future<void> deleteAll();
}
