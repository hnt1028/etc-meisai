import 'package:etc_meisai/application/dto/ic_match_list_dto.dart';
import 'package:etc_meisai/application/dto/ic_point_dto.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-1 of SCR-004: the IC names that need a choice, and the registered
/// mappings. It is read again when a mapping changes or the statement lines
/// change.
final icMatchListProvider = FutureProvider<IcMatchListDTO>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(listIcMatchesUCProvider).execute();
}, retry: (_, _) => null);

/// OP-2 of SCR-004: the IC points whose name has the typed text.
final icPointSearchProvider = FutureProvider.autoDispose
    .family<List<IcPointDTO>, String>(
      (ref, query) => ref.read(searchIcPointsUCProvider).execute(query),
      retry: (_, _) => null,
    );

final icMappingActionsProvider = Provider<IcMappingActions>(
  IcMappingActions.new,
);

/// OP-3 and OP-4 of SCR-004. They tell the other screens that the route
/// names may have changed.
class IcMappingActions {
  IcMappingActions(this._ref);

  final Ref _ref;

  /// Throws what the use case throws, so that the screen can say it failed.
  Future<void> save(String icName, String pointId) async {
    try {
      await _ref
          .read(saveIcMappingUCProvider)
          .execute(icName: icName, pointId: pointId);
    } finally {
      _ref.read(dataRevisionProvider.notifier).changed();
    }
  }

  Future<void> delete(String icName) async {
    try {
      await _ref.read(deleteIcMappingUCProvider).execute(icName);
    } finally {
      _ref.read(dataRevisionProvider.notifier).changed();
    }
  }
}
