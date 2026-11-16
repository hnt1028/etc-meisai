import 'dart:typed_data';

import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/aggregate_statements_uc.dart';
import 'package:etc_meisai/application/usecase/statements/statement_line_copy.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// A fictional statement line.
int _fakeIdCounter = 0;

StatementLineEntity fakeStatementLine({
  String? id,
  bool withoutVehicleNumber = false,
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
    id: id ?? 'line-${_fakeIdCounter++}',
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
    vehicleNumber: withoutVehicleNumber ? null : vehicleNumber,
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
  Future<StatementLineEntity?> findById(String id) async {
    if (readError != null) throw readError!;
    for (final s in stored) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> updateVehicleNumber(String id, int vehicleNumber) async {
    await gate;
    if (error != null) throw error!;
    final index = stored.indexWhere((s) => s.id == id);
    if (index >= 0) {
      stored[index] = copyWithVehicleNumber(stored[index], vehicleNumber);
    }
  }

  @override
  Future<void> updateEntrance(
    String id, {
    DateTime? entranceAt,
    String? entranceIc,
  }) async {
    await gate;
    if (error != null) throw error!;
    final index = stored.indexWhere((s) => s.id == id);
    if (index >= 0) {
      stored[index] = copyWithEntrance(
        stored[index],
        entranceAt: entranceAt,
        entranceIc: entranceIc,
      );
    }
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
  FakeIcMasterIF(this.points, {this.links = const [], this.error});

  final List<IcPointEntity> points;
  final List<IcLinkEntity> links;
  Object? error;

  @override
  Future<List<IcLinkEntity>> findLinks() async {
    if (error != null) throw error!;
    return links;
  }

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

/// Keeps the positions the user chose in memory. Can fail on request.
class FakeIcPositionIF implements IcPositionIF {
  final List<IcPositionEntity> stored = [];

  /// When set, every method throws it.
  Object? error;

  /// When set, only [save] / only [delete] throws it.
  Object? saveError;
  Object? deleteError;

  @override
  Future<List<IcPositionEntity>> findAll() async {
    if (error != null) throw error!;
    return List.of(stored);
  }

  @override
  Future<void> save(IcPositionEntity position) async {
    if (error != null) throw error!;
    if (saveError != null) throw saveError!;
    stored.removeWhere((p) => p.icName == position.icName);
    stored.add(position);
  }

  @override
  Future<void> delete(String icName) async {
    if (error != null) throw error!;
    if (deleteError != null) throw deleteError!;
    stored.removeWhere((p) => p.icName == icName);
  }
}

/// The statement list use case on in-memory fakes. With no IC points, no line
/// has a route name.
ListStatementLinesUC fakeListUC(
  FakeStatementLineIF lines, {
  List<IcPointEntity> points = const [],
  FakeIcMappingIF? mappings,
  FakeIcPositionIF? positions,
}) {
  return ListStatementLinesUC(
    statementLines: lines,
    icMaster: FakeIcMasterIF(points),
    icMappings: mappings ?? FakeIcMappingIF(),
    icPositions: positions ?? FakeIcPositionIF(),
  );
}

/// The route map use case on in-memory fakes.
ListRouteMapUC fakeRouteMapUC(
  FakeStatementLineIF lines, {
  FakeIcMasterIF? master,
  FakeIcMappingIF? mappings,
  FakeIcPositionIF? positions,
}) {
  return ListRouteMapUC(
    statementLines: lines,
    icMaster: master ?? FakeIcMasterIF([]),
    icMappings: mappings ?? FakeIcMappingIF(),
    icPositions: positions ?? FakeIcPositionIF(),
  );
}

/// The aggregation use case on in-memory fakes.
AggregateStatementsUC fakeAggregateUC(
  FakeStatementLineIF lines, {
  FakeIcMasterIF? master,
  FakeIcMappingIF? mappings,
  FakeIcPositionIF? positions,
}) {
  return AggregateStatementsUC(
    statementLines: lines,
    icMaster: master ?? FakeIcMasterIF([]),
    icMappings: mappings ?? FakeIcMappingIF(),
    icPositions: positions ?? FakeIcPositionIF(),
  );
}
