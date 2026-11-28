import 'package:etc_meisai/domain/entity/operator_color_entity.dart';

/// Stores the colors the user chose for the road operators.
abstract interface class OperatorColorIF {
  /// Returns every color the user chose.
  Future<List<OperatorColorEntity>> findAll();

  /// Stores [color], replacing the one of the same operator.
  Future<void> save(OperatorColorEntity color);

  /// Deletes the color of [operatorName]. Does nothing when there is none.
  Future<void> delete(String operatorName);

  /// Deletes every color.
  Future<void> deleteAll();
}
