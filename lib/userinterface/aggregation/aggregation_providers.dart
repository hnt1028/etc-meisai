import 'package:etc_meisai/application/usecase/aggregation/aggregate_statements_uc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use case is built in lib/main.dart (the only place that wires the
/// layers together) and given here with a ProviderScope override.
final aggregateStatementsUCProvider = Provider<AggregateStatementsUC>(
  (ref) => throw UnimplementedError('Override aggregateStatementsUCProvider'),
);
