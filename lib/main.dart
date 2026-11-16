// coverage:ignore-file
// The only place that wires the layers together. It opens the real database,
// so it is checked by the integration test, not by unit tests.
import 'package:drift_flutter/drift_flutter.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/delete_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/list_ic_matches_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/save_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/application/usecase/aggregation/aggregate_statements_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_mapping_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_master_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_position/ic_position_repo.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_providers.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final database = AppDatabase(driftDatabase(name: 'etc_meisai'));
  final statementLines = StatementLineRepo(database);
  final icMaster = IcMasterRepo(
    loadJson: () => rootBundle.loadString('assets/ic_master.json'),
  );
  final icMappings = IcMappingRepo(database);
  final icPositions = IcPositionRepo(database);

  runApp(
    ProviderScope(
      overrides: [
        importStatementUCProvider.overrideWithValue(
          ImportStatementUC(
            statement: const StatementRepo(),
            statementLines: statementLines,
          ),
        ),
        deleteAllStatementLinesUCProvider.overrideWithValue(
          DeleteAllStatementLinesUC(statementLines: statementLines),
        ),
        listStatementLinesUCProvider.overrideWithValue(
          ListStatementLinesUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        listRouteMapUCProvider.overrideWithValue(
          ListRouteMapUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        saveIcPositionUCProvider.overrideWithValue(
          SaveIcPositionUC(icPositions: icPositions),
        ),
        deleteIcPositionUCProvider.overrideWithValue(
          DeleteIcPositionUC(icPositions: icPositions),
        ),
        aggregateStatementsUCProvider.overrideWithValue(
          AggregateStatementsUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        saveVehicleNumberUCProvider.overrideWithValue(
          SaveVehicleNumberUC(statementLines: statementLines),
        ),
        getLineRouteUCProvider.overrideWithValue(
          GetLineRouteUC(
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        listIcMatchesUCProvider.overrideWithValue(
          ListIcMatchesUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
          ),
        ),
        searchIcPointsUCProvider.overrideWithValue(
          SearchIcPointsUC(icMaster: icMaster),
        ),
        saveIcMappingUCProvider.overrideWithValue(
          SaveIcMappingUC(icMaster: icMaster, icMappings: icMappings),
        ),
        deleteIcMappingUCProvider.overrideWithValue(
          DeleteIcMappingUC(icMappings: icMappings),
        ),
      ],
      child: const EtcMeisaiApp(),
    ),
  );
}
