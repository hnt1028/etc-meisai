import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The filter of the statement list and the route map: a period, a vehicle
/// number and a card number. The state is shared (statementFilterProvider).
class StatementFilterBar extends ConsumerWidget {
  const StatementFilterBar({
    super.key,
    required this.filter,
    required this.vehicleNumberChoices,
    required this.cardNumberChoices,
  });

  final StatementFilterState filter;
  final List<int> vehicleNumberChoices;
  final List<String> cardNumberChoices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(statementFilterProvider.notifier);
    final from = filter.from;
    final to = filter.to;
    final periodText = from != null && to != null
        ? StatementListStrings.period(from, to)
        : StatementListStrings.periodNone;

    return Padding(
      // The bottom padding keeps the controls apart from what is under them
      // (the map, the aggregation).
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(StatementListStrings.choiceAll),
                    ),
                    for (final number in vehicleNumberChoices)
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
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(StatementListStrings.choiceAll),
                    ),
                    for (final suffix in cardNumberChoices)
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
