// coverage:ignore-file
// The only place that wires the layers together. It opens the real database,
// so it is checked by the integration test, not by unit tests.
import 'package:drift_flutter/drift_flutter.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final database = AppDatabase(driftDatabase(name: 'etc_meisai'));
  final statementLines = StatementLineRepo(database);

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
          ListStatementLinesUC(statementLines: statementLines),
        ),
      ],
      child: const EtcMeisaiApp(),
    ),
  );
}
