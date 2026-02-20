import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final Schedule schedule;

  const StatusChip({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: switch (schedule.scheduleState) {
          ScheduleState.completed => colorScheme.onSurface,
          ScheduleState.draft => Color(0XFFFFA500),
          ScheduleState.published => Color(0xFF52A94F),
        },
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        switch (schedule.scheduleState) {
          ScheduleState.completed => AppLocalizations.of(context)!.completed,
          ScheduleState.draft => AppLocalizations.of(context)!.draft,
          ScheduleState.published => AppLocalizations.of(context)!.published,
        },
        style: textTheme.bodyMedium!.copyWith(
          color: switch (schedule.scheduleState) {
            ScheduleState.completed => colorScheme.surface,
            ScheduleState.draft => colorScheme.onSurface,
            ScheduleState.published => colorScheme.surface,
          },
          fontSize: 13,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
