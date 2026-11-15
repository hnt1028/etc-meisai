import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/dto/statement_list_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SCR-002: lists the statement lines with a filter and the total fare.
class StatementListScreen extends ConsumerWidget {
  const StatementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(statementListProvider);
    final filter = ref.watch(statementFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(StatementListStrings.title)),
      body: list.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MessageText(StatementListStrings.loadFailed, isError: true),
              TextButton(
                onPressed: () => ref.invalidate(statementListProvider),
                child: const Text(StatementListStrings.retry),
              ),
            ],
          ),
        ),
        data: (data) => Column(
          children: [
            if (list.isLoading) const LinearProgressIndicator(),
            _FilterBar(filter: filter, data: data),
            _Totals(data: data),
            const Divider(height: 1),
            Expanded(
              child: _Lines(data: data, filtered: filter.isActive),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter, required this.data});

  final StatementFilterState filter;
  final StatementListDTO data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(statementFilterProvider.notifier);
    final from = filter.from;
    final to = filter.to;
    final periodText = from != null && to != null
        ? StatementListStrings.period(from, to)
        : StatementListStrings.periodNone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: from != null && to != null
                    ? DateTimeRange(start: from, end: to)
                    : null,
              );
              if (range != null) controller.setPeriod(range.start, range.end);
            },
            child: Text('${StatementListStrings.periodLabel}: $periodText'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('vehicle-${filter.vehicleNumber}'),
                  initialValue: filter.vehicleNumber,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: StatementListStrings.vehicleNumberLabel,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(StatementListStrings.choiceAll),
                    ),
                    for (final number in data.vehicleNumberChoices)
                      DropdownMenuItem<int?>(
                        value: number,
                        child: Text('$number'),
                      ),
                  ],
                  onChanged: controller.setVehicleNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('card-${filter.cardNumberSuffix}'),
                  initialValue: filter.cardNumberSuffix,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: StatementListStrings.cardNumberLabel,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(StatementListStrings.choiceAll),
                    ),
                    for (final suffix in data.cardNumberChoices)
                      DropdownMenuItem<String?>(
                        value: suffix,
                        child: Text(
                          StatementListStrings.cardNumberChoice(suffix),
                        ),
                      ),
                  ],
                  onChanged: controller.setCardNumberSuffix,
                ),
              ),
            ],
          ),
          if (filter.isActive)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.clear,
                child: const Text(StatementListStrings.clearFilter),
              ),
            ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.data});

  final StatementListDTO data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StatementListStrings.totalFare(data.totalFare),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            StatementListStrings.totalBreakdown(
              data.totalFareAfterRebate,
              data.totalPostpaidFare,
            ),
          ),
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.data, required this.filtered});

  final StatementListDTO data;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    if (data.lines.isEmpty) {
      return Center(
        child: Text(
          filtered
              ? StatementListStrings.emptyNoMatch
              : StatementListStrings.emptyNoData,
        ),
      );
    }
    return ListView.separated(
      itemCount: data.lines.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _LineTile(line: data.lines[index]),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final StatementLineDTO line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(StatementListStrings.route(line.entranceIc, line.exitIc)),
      subtitle: Text(StatementListStrings.times(line.entranceAt, line.exitAt)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatYen(line.fare)),
          if (line.status == ConfirmationStatusValue.pending)
            Text(
              StatementListStrings.pending,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
