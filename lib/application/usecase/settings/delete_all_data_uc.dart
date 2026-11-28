import 'package:etc_meisai/application/interface/app_data_if.dart';

/// Deletes everything that is stored: the statement lines, the IC mappings and
/// the IC positions. Design: PRC-019.
class DeleteAllDataUC {
  const DeleteAllDataUC({required this.appData});

  final AppDataIF appData;

  Future<void> execute() => appData.deleteAll();
}
