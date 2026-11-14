import '../../domain/entity/trip_entity.dart';

/// Stores and reads trips on the device.
///
/// Rules such as "confirmed trips are never overwritten" belong to the
/// usecase, not to implementations of this interface.
abstract interface class TripIF {
  /// Returns the stored trip that has the same duplicate key as [trip],
  /// or null when there is none.
  ///
  /// The key is entrance date and time, entrance IC, exit IC and card number.
  Future<TripEntity?> findSame(TripEntity trip);

  /// Stores [trip]. If a trip with the same duplicate key is already stored,
  /// it is replaced.
  Future<void> save(TripEntity trip);

  /// Returns every stored trip.
  Future<List<TripEntity>> findAll();

  /// Removes every stored trip.
  Future<void> deleteAll();
}
