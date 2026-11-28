import 'package:etc_meisai/domain/entity/geo_point_entity.dart';

/// Two points of the IC master that are next to each other along the roads,
/// the length of the road between them, and its shape (docs/route-map.md).
class IcLinkEntity {
  const IcLinkEntity({
    required this.fromId,
    required this.toId,
    required this.meters,
    this.shape = const [],
  });

  /// The ids of the two IC points. The link has no direction.
  final String fromId;
  final String toId;

  /// The length of the road between the two points, in meters.
  final int meters;

  /// The shape of the road from [fromId] to [toId]: the points between the two
  /// (they are not in it). Empty when the road is not known.
  final List<GeoPointEntity> shape;
}
