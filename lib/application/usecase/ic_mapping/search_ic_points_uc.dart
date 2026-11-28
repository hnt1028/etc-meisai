import 'package:etc_meisai/application/dto/ic_point_dto.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// Searches the IC master by name. Design: PRC-006.
class SearchIcPointsUC {
  const SearchIcPointsUC({required this.icMaster});

  final IcMasterIF icMaster;

  /// At most this many points are returned.
  static const maxCount = 50;

  Future<List<IcPointDTO>> execute(String query) async {
    final key = IcLookup.fold(query.trim());
    if (key.isEmpty) return const [];

    final points = await icMaster.findAll();
    final matched = [
      for (final p in points)
        if (IcLookup.fold(p.name).contains(key)) p,
    ];
    matched.sort((a, b) {
      final aFirst = IcLookup.fold(a.name).startsWith(key);
      final bFirst = IcLookup.fold(b.name).startsWith(key);
      if (aFirst != bFirst) return aFirst ? -1 : 1;
      return IcLookup.fold(a.name).compareTo(IcLookup.fold(b.name));
    });
    return [for (final p in matched.take(maxCount)) toIcPointDTO(p)];
  }
}

/// Makes the DTO of an IC point.
IcPointDTO toIcPointDTO(IcPointEntity point) => IcPointDTO(
  id: point.id,
  name: point.name,
  kind: point.kind,
  latitude: point.latitude,
  longitude: point.longitude,
  routeNames: List.unmodifiable(point.routeNames),
);
