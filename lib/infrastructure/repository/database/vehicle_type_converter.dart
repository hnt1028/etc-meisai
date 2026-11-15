import 'package:drift/drift.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// Stores a [VehicleTypeValue] as its CSV number (not its position in the enum).
class VehicleTypeConverter extends TypeConverter<VehicleTypeValue, int> {
  const VehicleTypeConverter();

  @override
  VehicleTypeValue fromSql(int fromDb) => VehicleTypeValue.fromCode(fromDb)!;

  @override
  int toSql(VehicleTypeValue value) => value.code;
}
