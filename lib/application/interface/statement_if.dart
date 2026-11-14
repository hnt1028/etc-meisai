import 'dart:typed_data';

import '../../domain/entity/trip_entity.dart';

/// Reads a usage statement CSV into trips.
abstract interface class StatementIF {
  /// Parses the raw bytes of a usage statement CSV (CP932).
  ///
  /// Throws a [FormatException] that says what is invalid when the header or
  /// a row does not match the format. Nothing is silently skipped.
  List<TripEntity> parse(Uint8List bytes);
}
