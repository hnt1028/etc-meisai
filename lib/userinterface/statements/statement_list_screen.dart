import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/dto/statement_list_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/statements/statement_filter_bar.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// SCR-002: lists the statement lines with a filter and the total fare.
class StatementListScreen extends ConsumerWidget {
  const StatementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(statementListProvider);
    final filter = ref.watch(statementFilterProvider);
    final mode = ref.watch(statementListModeProvider);

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
        data: (data) => LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              if (list.isLoading) const LinearProgressIndicator(),
              // On a short screen (a phone held sideways), the header takes at
              // most half of the height and scrolls, so that it does not
              // overflow and the lines still have room.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: box.maxHeight * 0.5),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ModeSwitch(mode: mode),
                      StatementFilterBar(
                        filter: filter,
                        vehicleNumberChoices: data.vehicleNumberChoices,
                        cardNumberChoices: data.cardNumberChoices,
                        tagChoices: data.tagChoices,
                      ),
                      _Totals(data: data),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: data.lines.isEmpty
                    ? _Empty(filtered: filter.isActive)
                    : mode == StatementListMode.list
                    ? _Lines(data: data)
                    : StatementTimeline(lines: data.lines),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.data});

  final StatementListDTO data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StatementListStrings.totalFare(data.totalFare),
              style: theme.textTheme.titleLarge,
            ),
            Text(
              StatementListStrings.totalBreakdown(
                data.totalFareAfterRebate,
                data.totalPostpaidFare,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends ConsumerWidget {
  const _ModeSwitch({required this.mode});

  final StatementListMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<StatementListMode>(
          segments: const [
            ButtonSegment(
              value: StatementListMode.list,
              label: Text(StatementListStrings.modeList),
            ),
            ButtonSegment(
              value: StatementListMode.timeline,
              label: Text(StatementListStrings.modeTimeline),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => ref
              .read(statementListModeProvider.notifier)
              .select(selection.first),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        filtered
            ? StatementListStrings.emptyNoMatch
            : StatementListStrings.emptyNoData,
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.data});

  final StatementListDTO data;

  @override
  Widget build(BuildContext context) {
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
      onTap: () => context.push('/statements/detail', extra: line),
      title: Text(StatementListStrings.route(line.entranceIc, line.exitIc)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(StatementListStrings.times(line.entranceAt, line.exitAt)),
          if (line.routeNames.isNotEmpty)
            Text(StatementListStrings.routes(line.routeNames)),
          if (line.discountTypes.isNotEmpty)
            Text(StatementListStrings.discounts(line.discountTypes)),
          if (line.tags.isNotEmpty) Text(StatementListStrings.tags(line.tags)),
          if (line.memo.isNotEmpty)
            Text(line.memo, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatYen(line.fare)),
          if (line.status == ConfirmationStatusValue.pending)
            Text(
              StatementListStrings.pending,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
