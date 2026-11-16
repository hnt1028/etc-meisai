import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// Reads the IC master (the points bundled with the app).
abstract interface class IcMasterIF {
  /// Returns every IC point.
  Future<List<IcPointEntity>> findAll();

  /// Returns the links between the points that are next to each other along
  /// the roads. Empty when the master has none.
  Future<List<IcLinkEntity>> findLinks();
}
