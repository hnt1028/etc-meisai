import 'package:etc_meisai/application/dto/line_route_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use case is built in lib/main.dart (the only place that wires the
/// layers together) and given here with a ProviderScope override.
final getLineRouteUCProvider = Provider<GetLineRouteUC>(
  (ref) => throw UnimplementedError('Override getLineRouteUCProvider'),
);

/// The route of one statement line (PRC-012). It is read again every time the
/// detail screen is opened.
final lineRouteProvider = FutureProvider.autoDispose
    .family<LineRouteDTO, StatementLineDTO>(
      (ref, line) => ref.watch(getLineRouteUCProvider).execute(line),
      retry: (_, _) => null,
    );
