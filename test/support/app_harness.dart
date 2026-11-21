import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_layers_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_network_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_layer_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/reset_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_operator_color_uc.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/delete_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/list_ic_matches_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/save_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/application/usecase/aggregation/aggregate_statements_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/export_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_entrance_candidates_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/statements/estimate_entrance_at_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_entrance_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_mapping_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_master_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_position/ic_position_repo.dart';
import 'package:etc_meisai/infrastructure/repository/operator_color/operator_color_repo.dart';
import 'package:etc_meisai/infrastructure/repository/route_map_layer/route_map_layer_repo.dart';
import 'package:etc_meisai/infrastructure/repository/settings/app_data_repo.dart';
import 'package:etc_meisai/infrastructure/repository/settings/backup_repo.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_providers.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_layer_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:etc_meisai/userinterface/settings/backup_files.dart';
import 'package:etc_meisai/userinterface/settings/csv_picker.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/ic_master_fixture.dart';

/// Starts the whole app on [database], wired like lib/main.dart. Only the file
/// picker (it opens a system screen) and the IC master (a fictional one) are
/// replaced.
Future<void> pumpApp(
  WidgetTester tester, {
  required AppDatabase database,
  required CsvPicker picker,
  BackupPicker? backupPicker,
  BackupSaver? backupSaver,
}) async {
  final statementLines = StatementLineRepo(database);
  final icMaster = IcMasterRepo(loadJson: () async => icMasterFixtureJson());
  final icMappings = IcMappingRepo(database);
  final icPositions = IcPositionRepo(database);
  final operatorColors = OperatorColorRepo(database);
  final routeMapLayers = RouteMapLayerRepo(database);
  final appData = AppDataRepo(database);
  final backup = const BackupRepo();
  await tester.pumpWidget(
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
            vehicleTypes: FakeVehicleTypeMasterIF(),
          ),
        ),
        listRouteMapUCProvider.overrideWithValue(
          ListRouteMapUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
            vehicleTypes: FakeVehicleTypeMasterIF(),
          ),
        ),
        listRouteMapLayersUCProvider.overrideWithValue(
          ListRouteMapLayersUC(routeMapLayers: routeMapLayers),
        ),
        saveRouteMapLayerUCProvider.overrideWithValue(
          SaveRouteMapLayerUC(routeMapLayers: routeMapLayers),
        ),
        listRouteNetworkUCProvider.overrideWithValue(
          ListRouteNetworkUC(icMaster: icMaster),
        ),
        listOperatorColorsUCProvider.overrideWithValue(
          ListOperatorColorsUC(operatorColors: operatorColors),
        ),
        saveOperatorColorUCProvider.overrideWithValue(
          SaveOperatorColorUC(operatorColors: operatorColors),
        ),
        resetOperatorColorsUCProvider.overrideWithValue(
          ResetOperatorColorsUC(operatorColors: operatorColors),
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
        estimateEntranceAtUCProvider.overrideWithValue(
          EstimateEntranceAtUC(
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        exportDataUCProvider.overrideWithValue(
          ExportDataUC(appData: appData, backup: backup),
        ),
        importDataUCProvider.overrideWithValue(
          ImportDataUC(appData: appData, backup: backup),
        ),
        deleteAllDataUCProvider.overrideWithValue(
          DeleteAllDataUC(appData: appData),
        ),
        saveEntranceUCProvider.overrideWithValue(
          SaveEntranceUC(statementLines: statementLines),
        ),
        saveVehicleNumberUCProvider.overrideWithValue(
          SaveVehicleNumberUC(statementLines: statementLines),
        ),
        listEntranceCandidatesUCProvider.overrideWithValue(
          ListEntranceCandidatesUC(
            statementLines: statementLines,
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        getLineRouteUCProvider.overrideWithValue(
          GetLineRouteUC(
            icMaster: icMaster,
            icMappings: icMappings,
            icPositions: icPositions,
          ),
        ),
        // The map tiles need the network, so the tests draw no tiles.
        tileLayerProvider.overrideWithValue(const SizedBox.shrink()),
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
        csvPickerProvider.overrideWithValue(picker),
        backupPickerProvider.overrideWithValue(
          backupPicker ?? () async => null,
        ),
        backupSaverProvider.overrideWithValue(
          backupSaver ?? (name, bytes) async => false,
        ),
      ],
      // ignore: prefer_const_constructors
      child: EtcMeisaiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a screen from the navigation bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openStatements(WidgetTester tester) =>
    openTab(tester, AppStrings.statementsTab);

Future<void> openSettings(WidgetTester tester) =>
    openTab(tester, AppStrings.settingsTab);
