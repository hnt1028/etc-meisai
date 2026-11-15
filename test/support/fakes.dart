import 'dart:typed_data';

import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// A fictional statement line.
StatementLineEntity fakeStatementLine({
  String exitIc = 'B-IC',
  ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
  DateTime? exitAt,
  DateTime? entranceAt,
  String? entranceIc,
  bool withoutEntrance = false,
  int fare = 1000,
  int fareAfterRebate = 0,
  int? postpaidFare,
  int vehicleNumber = 1234,
  String cardNumber = '0000-****-0001',
  int? grossFare,
  int? etcDiscount,
  VehicleTypeValue vehicleType = VehicleTypeValue.standard,
  List<String> discountTypes = const [],
}) {
  return StatementLineEntity(
    entranceAt: withoutEntrance
        ? null
        : (entranceAt ?? DateTime(2026, 1, 10, 8, 30)),
    exitAt: exitAt ?? DateTime(2026, 1, 10, 9, 15),
    entranceIc: withoutEntrance ? null : (entranceIc ?? 'A-IC'),
    exitIc: exitIc,
    grossFare: grossFare,
    etcDiscount: etcDiscount,
    fare: fare,
    fareAfterRebate: fareAfterRebate,
    postpaidFare: postpaidFare ?? fare - fareAfterRebate,
    vehicleType: vehicleType,
    vehicleNumber: vehicleNumber,
    cardNumber: cardNumber,
    status: status,
    discountTypes: discountTypes,
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

/// A fictional IC point.
IcPointEntity fakeIcPoint({
  String? id,
  required String name,
  IcKindValue kind = IcKindValue.generalInterchange,
  List<String> routeNames = const ['テスト自動車道'],
  double latitude = 35.0,
  double longitude = 139.0,
}) {
  return IcPointEntity(
    id: id ?? 'id-$name',
    name: name,
    kind: kind,
    latitude: latitude,
    longitude: longitude,
    routeNames: routeNames,
  );
}

/// Returns the given IC points, or throws [error].
class FakeIcMasterIF implements IcMasterIF {
  FakeIcMasterIF(this.points, {this.error});

  final List<IcPointEntity> points;
  Object? error;

  @override
  Future<List<IcPointEntity>> findAll() async {
    if (error != null) throw error!;
    return points;
  }
}

/// Keeps IC mappings in memory. Can fail on request.
class FakeIcMappingIF implements IcMappingIF {
  final List<IcMappingEntity> stored = [];

  /// When set, every method throws it.
  Object? error;

  @override
  Future<List<IcMappingEntity>> findAll() async {
    if (error != null) throw error!;
    return List.of(stored);
  }

  @override
  Future<void> save(IcMappingEntity mapping) async {
    if (error != null) throw error!;
    stored.removeWhere((m) => m.icName == mapping.icName);
    stored.add(mapping);
  }

  @override
  Future<void> delete(String icName) async {
    if (error != null) throw error!;
    stored.removeWhere((m) => m.icName == icName);
  }
}

/// The statement list use case on in-memory fakes. With no IC points, no line
/// has a route name.
ListStatementLinesUC fakeListUC(
  FakeStatementLineIF lines, {
  List<IcPointEntity> points = const [],
  FakeIcMappingIF? mappings,
}) {
  return ListStatementLinesUC(
    statementLines: lines,
    icMaster: FakeIcMasterIF(points),
    icMappings: mappings ?? FakeIcMappingIF(),
  );
}
