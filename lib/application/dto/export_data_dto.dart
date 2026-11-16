import 'dart:typed_data';

import 'package:etc_meisai/application/dto/data_summary_dto.dart';

/// The backup file to save. Design: PRC-017.
class ExportDataDTO {
  const ExportDataDTO({
    required this.fileName,
    required this.bytes,
    required this.summary,
  });

  final String fileName;

  /// The content of the file. It has personal data.
  final Uint8List bytes;

  /// How many of each kind of data are in it.
  final DataSummaryDTO summary;
}
