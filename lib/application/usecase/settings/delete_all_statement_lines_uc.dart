import 'package:etc_meisai/application/interface/statement_line_if.dart';

/// Deletes every stored statement line. Design: PRC-003.
class DeleteAllStatementLinesUC {
  const DeleteAllStatementLinesUC({required this.statementLines});

  final StatementLineIF statementLines;

  Future<void> execute() => statementLines.deleteAll();
}
