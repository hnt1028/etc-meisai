import 'dart:typed_data';

import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// A fictional statement line.
StatementLineEntity fakeStatementLine({
  String exitIc = 'B-IC',
  ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
  DateTime? exitAt,
  bool withoutEntrance = false,
  int fare = 1000,
  int fareAfterRebate = 0,
  int? postpaidFare,
  int vehicleNumber = 1234,
  String cardNumber = '0000-****-0001',
}) {
  return StatementLineEntity(
    entranceAt: withoutEntrance ? null : DateTime(2026, 1, 10, 8, 30),
    exitAt: exitAt ?? DateTime(2026, 1, 10, 9, 15),
    entranceIc: withoutEntrance ? null : 'A-IC',
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: fare,
    fareAfterRebate: fareAfterRebate,
    postpaidFare: postpaidFare ?? fare - fareAfterRebate,
    vehicleType: VehicleTypeValue.standard,
    vehicleNumber: vehicleNumber,
    cardNumber: cardNumber,
    status: status,
    discountTypes: const [],
  );
}

/// Returns the given lines, or throws [error].
class FakeStatementIF implements StatementIF {
  FakeStatementIF(this.lines, {this.error});

  final List<StatementLineEntity> lines;
  final Object? error;

  @override
  List<StatementLineEntity> parse(Uint8List bytes) {
    if (error != null) throw error!;
    return lines;
  }
}

/// Keeps statement lines in memory. Can fail or wait on request.
class FakeStatementLineIF implements StatementLineIF {
  final List<StatementLineEntity> stored = [];

  /// When set, [save] and [deleteAll] throw it.
  Object? error;

  /// When set, [save] and [deleteAll] wait for it.
  Future<void>? gate;

  /// When set, [findAll] throws it.
  Object? readError;

  /// When set, [findAll] waits for it.
  Future<void>? readGate;

  /// How many times [findAll] was called.
  int readCount = 0;

  String _key(StatementLineEntity l) =>
      '${l.entranceAt}|${l.entranceIc}|${l.exitIc}|${l.cardNumber}';

  @override
  Future<StatementLineEntity?> findSame(StatementLineEntity line) async {
    for (final s in stored) {
      if (_key(s) == _key(line)) return s;
    }
    return null;
  }

  @override
  Future<void> save(StatementLineEntity line) async {
    await gate;
    if (error != null) throw error!;
    stored.removeWhere((s) => _key(s) == _key(line));
    stored.add(line);
  }

  @override
  Future<List<StatementLineEntity>> findAll() async {
    readCount++;
    await readGate;
    if (readError != null) throw readError!;
    return List.of(stored);
  }

  @override
  Future<void> deleteAll() async {
    await gate;
    if (error != null) throw error!;
    stored.clear();
  }
}
