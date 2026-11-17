import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/reset_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_operator_color_uc.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final listOperatorColorsUCProvider = Provider<ListOperatorColorsUC>(
  (ref) => throw UnimplementedError('Override listOperatorColorsUCProvider'),
);

final saveOperatorColorUCProvider = Provider<SaveOperatorColorUC>(
  (ref) => throw UnimplementedError('Override saveOperatorColorUCProvider'),
);

final resetOperatorColorsUCProvider = Provider<ResetOperatorColorsUC>(
  (ref) => throw UnimplementedError('Override resetOperatorColorsUCProvider'),
);

/// The colors of the lines of every operator (PRC-021). It is read again when
/// the stored data is replaced or deleted (a restore, a deletion), and by the
/// settings screen after a color is saved or reset.
final operatorColorsProvider = FutureProvider<List<OperatorColorDTO>>((
  ref,
) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(listOperatorColorsUCProvider).execute();
}, retry: (_, _) => null);
