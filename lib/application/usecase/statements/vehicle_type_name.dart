import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/domain/entity/vehicle_type_division_entity.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// The name of a vehicle type number on a line that ran on [routeNames]
/// (docs/vehicle-types.md). The division is, in this order: the one whose
/// roads the line ran on (the roads of the divisions 2 and 3 of NEXCO, which
/// the route operators table may not know); else the one of the operator of
/// the routes. The name of the default table ([VehicleTypeValue.label]) when
/// there is no such division (the operator is not known, or is more than
/// one), or the division has no name for the number.
String vehicleTypeNameOf(
  VehicleTypeValue vehicleType,
  List<String> routeNames,
  List<VehicleTypeDivisionEntity> divisions,
) {
  VehicleTypeDivisionEntity? chosen;
  for (final d in divisions) {
    if (routeNames.any((r) => d.roads.any(r.contains))) {
      chosen = d;
      break;
    }
  }
  if (chosen == null) {
    final operator = operatorOfRoutes(routeNames);
    for (final d in divisions) {
      if (d.roads.isEmpty && d.operators.contains(operator)) {
        chosen = d;
        break;
      }
    }
  }
  return chosen?.names[vehicleType.code - 1] ?? vehicleType.label;
}
