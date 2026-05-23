import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';

class VaccineCalendarPage extends ConsumerStatefulWidget {
  const VaccineCalendarPage({super.key});

  @override
  ConsumerState<VaccineCalendarPage> createState() =>
      _VaccineCalendarPageState();
}

class _VaccineCalendarPageState extends ConsumerState<VaccineCalendarPage> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(
      () => _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calendarAsync = ref.watch(vaccineCalendarProvider);
    final monthLabel =
        '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaccineCalendarTitle)),
      body: calendarAsync.when(
        loading: VaccineFeedback.loading,
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(vaccineCalendarProvider),
        ),
        data: (days) {
          final monthDays = days.where(
            (d) =>
                d.date.year == _focusedMonth.year &&
                d.date.month == _focusedMonth.month,
          );
          final byDay = {
            for (final day in monthDays) day.date.day: day.records,
          };
          final firstWeekday = DateTime(
            _focusedMonth.year,
            _focusedMonth.month,
            1,
          ).weekday;
          final daysInMonth = DateTime(
            _focusedMonth.year,
            _focusedMonth.month + 1,
            0,
          ).day;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vaccineCalendarProvider);
              await ref.read(vaccineCalendarProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemCount: firstWeekday - 1 + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday - 1) {
                      return const SizedBox.shrink();
                    }
                    final day = index - (firstWeekday - 1) + 1;
                    final records = byDay[day] ?? const [];
                    return InkWell(
                      onTap: records.isEmpty
                          ? null
                          : () => context.push(
                              AppRoutes.vaccineDetail(records.first.id),
                            ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: records.isEmpty
                              ? null
                              : Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day'),
                            if (records.isNotEmpty)
                              Text(
                                '${records.length}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.vaccineCalendarLegend,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...monthDays.map(
                  (day) => ListTile(
                    dense: true,
                    title: Text(day.date.toLocal().toString().split(' ').first),
                    subtitle: Text(
                      day.records.map((r) => r.vaccineName).join(', '),
                    ),
                    trailing: Text('${day.records.length}'),
                    onTap: () => context.push(
                      AppRoutes.vaccineDetail(day.records.first.id),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
