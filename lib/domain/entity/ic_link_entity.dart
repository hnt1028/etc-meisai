/// Two points of the IC master that are next to each other along the roads,
/// and the length of the road between them (docs/route-map.md).
class IcLinkEntity {
  const IcLinkEntity({
    required this.fromId,
    required this.toId,
    required this.meters,
  });

  /// The ids of the two IC points. The link has no direction.
  final String fromId;
  final String toId;

  /// The length of the road between the two points, in meters.
  final int meters;
}
