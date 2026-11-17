import 'dart:typed_data';

import 'package:etc_meisai/application/usecase/settings/delete_all_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/export_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_data_uc.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

AppDataEntity _data({int lines = 2, int mappings = 1, int positions = 3}) =>
    AppDataEntity(
      statementLines: [
        for (var i = 0; i < lines; i++)
          fakeRecord(id: 'id-$i', duplicateKey: 'key-$i'),
      ],
      icMappings: [
        for (var i = 0; i < mappings; i++)
          IcMappingEntity(icName: 'ic-$i', pointId: 'p-$i'),
      ],
      icPositions: [
        for (var i = 0; i < positions; i++)
          IcPositionEntity(icName: 'pos-$i', latitude: 35, longitude: 139),
      ],
      operatorColors: const [
        OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF112233),
      ],
    );

void main() {
  group('ExportDataUC', () {
    final now = DateTime(2026, 11, 16, 9, 5, 30);

    test('gives the file, named by the time, with the counts', () async {
      final backup = FakeBackupIF();
      final uc = ExportDataUC(
        appData: FakeAppDataIF(_data()),
        backup: backup,
        now: () => now,
      );

      final result = await uc.execute();

      expect(result.fileName, 'etc-meisai-backup-20261116-0905.json');
      expect(result.bytes, Uint8List.fromList([1, 2, 3]));
      expect(result.summary.lineCount, 2);
      expect(result.summary.mappingCount, 1);
      expect(result.summary.positionCount, 3);
      // The file got everything that is stored, and the time of the export.
      expect(backup.encodedData!.statementLines, hasLength(2));
      expect(backup.encodedAt, now);
    });

    test('pads the month, the day, the hour and the minute', () async {
      final uc = ExportDataUC(
        appData: FakeAppDataIF(),
        backup: FakeBackupIF(),
        now: () => DateTime(2026, 1, 2, 3, 4),
      );

      expect(
        (await uc.execute()).fileName,
        'etc-meisai-backup-20260102-0304.json',
      );
    });

    test('exports nothing as a file with no data', () async {
      final uc = ExportDataUC(
        appData: FakeAppDataIF(),
        backup: FakeBackupIF(),
        now: () => now,
      );

      final result = await uc.execute();

      expect(result.summary.lineCount, 0);
      expect(result.summary.mappingCount, 0);
      expect(result.summary.positionCount, 0);
      expect(result.bytes, isNotEmpty);
    });

    test('uses the real clock when none is given', () async {
      final before = DateTime.now();
      final uc = ExportDataUC(appData: FakeAppDataIF(), backup: FakeBackupIF());

      await uc.execute();

      final backup = FakeBackupIF();
      await ExportDataUC(appData: FakeAppDataIF(), backup: backup).execute();
      expect(backup.encodedAt!.isBefore(before), isFalse);
      expect(uc.now, isNotNull);
    });

    test('passes on a failure to read', () {
      final appData = FakeAppDataIF()..readError = StateError('x');
      final uc = ExportDataUC(appData: appData, backup: FakeBackupIF());

      expect(uc.execute(), throwsStateError);
    });
  });

  group('ImportDataUC', () {
    test('replaces everything with the file, and counts it', () async {
      final appData = FakeAppDataIF(_data(lines: 5, mappings: 5, positions: 5));
      final backup = FakeBackupIF(
        decoded: _data(lines: 2, mappings: 0, positions: 1),
      );

      final summary = await ImportDataUC(
        appData: appData,
        backup: backup,
      ).execute(Uint8List(0));

      expect(summary.lineCount, 2);
      expect(summary.mappingCount, 0);
      expect(summary.positionCount, 1);
      expect(appData.replaceCount, 1);
      expect(appData.data.statementLines, hasLength(2));
      expect(appData.data.icMappings, isEmpty);
    });

    test('changes nothing when the file is not a valid backup', () async {
      final appData = FakeAppDataIF(_data());
      final backup = FakeBackupIF(error: const FormatException('不正'));

      await expectLater(
        ImportDataUC(appData: appData, backup: backup).execute(Uint8List(0)),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', '不正'),
        ),
      );

      expect(appData.replaceCount, 0);
      expect(appData.data.statementLines, hasLength(2));
    });

    test('keeps what is stored when the replacement fails', () async {
      final appData = FakeAppDataIF(_data())..replaceError = StateError('disk');
      final backup = FakeBackupIF(decoded: _data(lines: 9));

      await expectLater(
        ImportDataUC(appData: appData, backup: backup).execute(Uint8List(0)),
        throwsStateError,
      );

      expect(appData.data.statementLines, hasLength(2));
    });
  });

  group('DeleteAllDataUC', () {
    test('deletes everything', () async {
      final appData = FakeAppDataIF(_data());

      await DeleteAllDataUC(appData: appData).execute();

      expect(appData.deleteCount, 1);
      expect(appData.data.statementLines, isEmpty);
      expect(appData.data.icMappings, isEmpty);
      expect(appData.data.icPositions, isEmpty);
    });

    test('passes on a failure, keeping the data', () async {
      final appData = FakeAppDataIF(_data())..deleteError = StateError('disk');

      await expectLater(
        DeleteAllDataUC(appData: appData).execute(),
        throwsStateError,
      );

      expect(appData.data.statementLines, hasLength(2));
    });
  });
}
