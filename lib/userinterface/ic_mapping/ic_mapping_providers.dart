import 'package:etc_meisai/application/usecase/ic_mapping/delete_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/list_ic_matches_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/save_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final listIcMatchesUCProvider = Provider<ListIcMatchesUC>(
  (ref) => throw UnimplementedError('Override listIcMatchesUCProvider'),
);

final searchIcPointsUCProvider = Provider<SearchIcPointsUC>(
  (ref) => throw UnimplementedError('Override searchIcPointsUCProvider'),
);

final saveIcMappingUCProvider = Provider<SaveIcMappingUC>(
  (ref) => throw UnimplementedError('Override saveIcMappingUCProvider'),
);

final deleteIcMappingUCProvider = Provider<DeleteIcMappingUC>(
  (ref) => throw UnimplementedError('Override deleteIcMappingUCProvider'),
);
