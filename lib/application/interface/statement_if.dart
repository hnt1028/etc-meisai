import 'dart:typed_data';

import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// Reads a usage statement CSV into statement lines.
abstract interface class StatementIF {
  /// Parses the raw bytes of a usage statement CSV (CP932).
  ///
  /// Throws a [FormatException] that says what is invalid when the header or
  /// a row does not match the format. Nothing is silently skipped.
  List<StatementLineEntity> parse(Uint8List bytes);
}
