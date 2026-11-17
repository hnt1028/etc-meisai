import 'dart:convert';

import 'package:etc_meisai/application/interface/vehicle_type_master_if.dart';
import 'package:etc_meisai/domain/entity/vehicle_type_division_entity.dart';

/// Reads the vehicle type divisions, which are
/// `assets/vehicle_type_master.json` (see docs/vehicle-types.md).
class VehicleTypeMasterRepo implements VehicleTypeMasterIF {
  VehicleTypeMasterRepo({required this.loadJson});

  /// Gives the text of the JSON file. The app passes a function that reads the
  /// asset (see lib/main.dart).
  final Future<String> Function() loadJson;

  List<VehicleTypeDivisionEntity>? _divisions;

  @override
  Future<List<VehicleTypeDivisionEntity>> findAll() async {
    return _divisions ??= _parse(jsonDecode(await loadJson()) as Map);
  }

  static List<VehicleTypeDivisionEntity> _parse(Map json) {
    return List.unmodifiable([
      for (final d in (json['divisions'] as List).cast<Map>())
        VehicleTypeDivisionEntity(
          id: d['id'] as String,
          operators: List.unmodifiable((d['operators'] as List).cast<String>()),
          roads: List.unmodifiable((d['roads'] as List).cast<String>()),
          names: List.unmodifiable((d['names'] as List).cast<String?>()),
        ),
    ]);
  }
}
