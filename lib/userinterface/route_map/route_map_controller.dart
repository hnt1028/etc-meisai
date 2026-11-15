import 'package:etc_meisai/application/dto/route_map_dto.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// OP-1 of SCR-005: what the map draws for the current filter. It is read
/// again when the filter or the stored data changes.
final routeMapProvider = FutureProvider<RouteMapDTO>((ref) {
  ref.watch(dataRevisionProvider);
  final filter = ref.watch(statementFilterProvider);
  return ref
      .read(listRouteMapUCProvider)
      .execute(
        from: filter.from,
        to: filter.to,
        vehicleNumber: filter.vehicleNumber,
        cardNumberSuffix: filter.cardNumberSuffix,
      );
}, retry: (_, _) => null);

/// The IC the user is choosing a position for, and the pin on the map.
class IcPickingState {
  const IcPickingState({this.icName, this.pin});

  /// Null when the user is not choosing a position.
  final String? icName;

  /// The point the user tapped. Null before the first tap.
  final LatLng? pin;
}

final icPickingProvider = NotifierProvider<IcPickingController, IcPickingState>(
  IcPickingController.new,
);

/// OP-3, OP-4, OP-6 and the start of OP-7 of SCR-005.
class IcPickingController extends Notifier<IcPickingState> {
  @override
  IcPickingState build() => const IcPickingState();

  /// Starts choosing a position for [icName].
  void start(String icName) => state = IcPickingState(icName: icName);

  /// Puts the pin on [point]. Does nothing when no position is being chosen.
  void setPin(LatLng point) {
    final icName = state.icName;
    if (icName != null) state = IcPickingState(icName: icName, pin: point);
  }

  /// Stops choosing and removes the pin.
  void cancel() => state = const IcPickingState();
}

final routeMapActionsProvider = Provider<RouteMapActions>(RouteMapActions.new);

/// OP-5 and the unspecify of OP-7 of SCR-005. They tell the other screens that
/// the route names may have changed.
class RouteMapActions {
  RouteMapActions(this._ref);

  final Ref _ref;

  /// Throws what the use case throws, so that the screen can say it failed.
  Future<void> savePosition(String icName, LatLng position) async {
    try {
      await _ref
          .read(saveIcPositionUCProvider)
          .execute(
            icName: icName,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } finally {
      _ref.read(dataRevisionProvider.notifier).changed();
    }
  }

  Future<void> deletePosition(String icName) async {
    try {
      await _ref.read(deleteIcPositionUCProvider).execute(icName);
    } finally {
      _ref.read(dataRevisionProvider.notifier).changed();
    }
  }
}
