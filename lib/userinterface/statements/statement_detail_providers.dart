import 'package:etc_meisai/application/dto/line_route_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/application/usecase/statements/estimate_entrance_at_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_entrance_candidates_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_entrance_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_line_note_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
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

/// OP-3 of SCR-003 (PRC-014). Also built in lib/main.dart.
final saveVehicleNumberUCProvider = Provider<SaveVehicleNumberUC>(
  (ref) => throw UnimplementedError('Override saveVehicleNumberUCProvider'),
);

/// OP-4 and OP-5 of SCR-003 (PRC-015). Also built in lib/main.dart.
final saveEntranceUCProvider = Provider<SaveEntranceUC>(
  (ref) => throw UnimplementedError('Override saveEntranceUCProvider'),
);

/// The choices for the entrance IC in OP-5 of SCR-003 (PRC-020). Also built in
/// lib/main.dart.
final listEntranceCandidatesUCProvider = Provider<ListEntranceCandidatesUC>(
  (ref) =>
      throw UnimplementedError('Override listEntranceCandidatesUCProvider'),
);

/// The entrance time to start with in OP-4 of SCR-003 (PRC-016). Also built in
/// lib/main.dart.
final estimateEntranceAtUCProvider = Provider<EstimateEntranceAtUC>(
  (ref) => throw UnimplementedError('Override estimateEntranceAtUCProvider'),
);

/// OP-6 of SCR-003 (PRC-027). Also built in lib/main.dart.
final saveLineNoteUCProvider = Provider<SaveLineNoteUC>(
  (ref) => throw UnimplementedError('Override saveLineNoteUCProvider'),
);
