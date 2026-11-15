import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';

/// Registers the position the user chose on the map for an IC name.
/// Design: PRC-010.
class SaveIcPositionUC {
  const SaveIcPositionUC({required this.icPositions});

  final IcPositionIF icPositions;

  /// Throws [ArgumentError] when the latitude is not from -90 to 90 or the
  /// longitude is not from -180 to 180 (NaN included).
  Future<void> execute({
    required String icName,
    required double latitude,
    required double longitude,
  }) async {
    if (!(latitude >= -90 && latitude <= 90)) {
      throw ArgumentError.value(latitude, 'latitude', 'out of range');
    }
    if (!(longitude >= -180 && longitude <= 180)) {
      throw ArgumentError.value(longitude, 'longitude', 'out of range');
    }
    await icPositions.save(
      IcPositionEntity(
        icName: icName,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }
}
