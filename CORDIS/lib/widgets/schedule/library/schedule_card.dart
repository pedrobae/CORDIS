import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/screens/schedule/view_schedule.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/duplicate_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleCard extends StatelessWidget {
  final dynamic scheduleId;
  final bool showActions;

  const ScheduleCard({
    super.key,
    required this.scheduleId,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer6<
      LocalScheduleProvider,
      CloudScheduleProvider,
      PlaylistProvider,
      MyAuthProvider,
      UserProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            playlistProvider,
            authProvider,
            userProvider,
            navigationProvider,
            child,
          ) {
            // LOADING STATE
            if (localScheduleProvider.isLoading ||
                cloudScheduleProvider.isLoading ||
                userProvider.isLoading ||
                scheduleId == -1) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final dynamic schedule = scheduleId is int
                ? localScheduleProvider.getSchedule(scheduleId)!
                : cloudScheduleProvider.getSchedule(scheduleId);

            final dynamic playlist = scheduleId is int
                ? playlistProvider.getPlaylistById(schedule.playlistId)
                : schedule.playlist;

            String userRole = AppLocalizations.of(context)!.generalMember;
            if (scheduleId is int) {
              final roleFound = localScheduleProvider.getUserRoleInSchedule(
                scheduleId,
                userProvider.getLocalIdByFirebaseId(authProvider.id!),
              );
              if (roleFound != null) {
                userRole = roleFound;
              }
            } else {
              for (var role in (schedule as ScheduleDto).roles) {
                if (role.memberIds.contains(authProvider.id)) {
                  userRole = role.name;
                  break;
                }
              }
            }

            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.surfaceContainerLowest,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SCHEDULE NAME
                            Text(
                              schedule.name,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),

                            // WHEN & WHERE
                            Wrap(
                              spacing: 16.0,
                              children: [
                                Text(
                                  schedule is ScheduleDto
                                      ? DateTimeUtils.formatDate(
                                          schedule.datetime.toDate(),
                                        )
                                      : DateTimeUtils.formatDate(
                                          (schedule as Schedule).date,
                                        ),
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  schedule is ScheduleDto
                                      ? DateTimeUtils.formatDate(
                                          schedule.datetime.toDate(),
                                        )
                                      : DateTimeUtils.formatDate(
                                          (schedule as Schedule).date,
                                        ),
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  schedule.location,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),

                            // PLAYLIST INFO
                            playlist != null
                                ? Text(
                                    '${AppLocalizations.of(context)!.playlist}: ${playlist.name}',
                                    style: theme.textTheme.bodyMedium,
                                  )
                                : SizedBox.shrink(),

                            // YOUR ROLE INFO
                            Text(
                              '${AppLocalizations.of(context)!.role}: $userRole',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (showActions) ...[
                        IconButton(
                          onPressed: () => _openScheduleActionsSheet(
                            context,
                            scheduleId,
                            localScheduleProvider,
                            cloudScheduleProvider,
                          ),
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ],
                  ),
                  // BOTTOM BUTTONS
                  FilledTextButton(
                    isDark: true,
                    isDense: true,
                    onPressed: () {
                      navigationProvider.push(
                        ViewScheduleScreen(scheduleId: scheduleId),
                        showAppBar: false,
                        showDrawerIcon: false,
                      );
                    },
                    text: AppLocalizations.of(
                      context,
                    )!.viewPlaceholder(AppLocalizations.of(context)!.schedule),
                  ),
                  FilledTextButton(
                    onPressed: () {
                      // TODO: CLOUD - Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.amberAccent,
                          content: Text(
                            'Funcionalidade em desenvolvimento,',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                    text: AppLocalizations.of(context)!.share,
                    isDense: true,
                  ),
                ],
              ),
            );
          },
    );
  }

  void _openScheduleActionsSheet(
    BuildContext context,
    dynamic scheduleId,
    LocalScheduleProvider localScheduleProvider,
    CloudScheduleProvider cloudScheduleProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.scheduleActions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // ACTIONS
              // duplicate
              FilledTextButton(
                text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
                tooltip: AppLocalizations.of(
                  context,
                )!.duplicateTooltip(AppLocalizations.of(context)!.setup),
                onPressed: () =>
                    _openDuplicateScheduleSheet(context, scheduleId),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
              ),
              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                tooltip: AppLocalizations.of(context)!.deleteScheduleTooltip,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.schedule,
                        onConfirm: () {
                          Navigator.of(context).pop();
                          scheduleId is int
                              ? localScheduleProvider.deleteSchedule(scheduleId)
                              : localScheduleProvider.deleteSchedule(
                                  scheduleId,
                                );
                        },
                      );
                    },
                  );
                },
                trailingIcon: Icons.chevron_right,
                isDangerous: true,
                isDiscrete: true,
              ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openDuplicateScheduleSheet(BuildContext context, dynamic scheduleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DuplicateScheduleSheet(scheduleId: scheduleId),
        );
      },
    );
  }
}
