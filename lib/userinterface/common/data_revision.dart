import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts how many times the stored statement lines changed (an import or a
/// deletion). Screens that show them watch it and read them again.
final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void changed() => state++;
}
