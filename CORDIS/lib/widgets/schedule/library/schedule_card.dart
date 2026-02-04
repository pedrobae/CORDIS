import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/schedule/view_schedule.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/duplicate_schedule_sheet.dart';
import 'package:cordis/widgets/schedule/library/share_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleCard extends StatelessWidget {
  final int scheduleId;
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

    return Consumer5<
      LocalScheduleProvider,
      PlaylistProvider,
      MyAuthProvider,
      UserProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            playlistProvider,
            authProvider,
            userProvider,
            navigationProvider,
            child,
          ) {
            // LOADING STATE
            if (localScheduleProvider.isLoading ||
                userProvider.isLoading ||
                scheduleId == -1) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final schedule = localScheduleProvider.getSchedule(scheduleId);

            final playlist = playlistProvider.getPlaylistById(
              schedule!.playlistId!,
            );

            String userRole = AppLocalizations.of(context)!.generalMember;
            final roleFound = localScheduleProvider.getUserRoleInSchedule(
              scheduleId,
              userProvider.getLocalIdByFirebaseId(authProvider.id!),
            );
            if (roleFound != null) {
              userRole = roleFound;
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
                                  DateTimeUtils.formatDate(schedule.date),
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(DateTimeUtils.formatDate(schedule.date)),
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
                          ),
                          onLongPress: () => _openScheduleActionsSheet(
                            context,
                            scheduleId,
                            localScheduleProvider,
                            secret: true,
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
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ShareScheduleSheet(scheduleId: scheduleId),
                          );
                        },
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
    int scheduleId,
    LocalScheduleProvider localScheduleProvider, {
    bool secret = false,
  }) {
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
              if (secret)
                FilledTextButton(
                  text: 'UPLOAD',
                  onPressed: () {
                    final cloudScheduleProvider = context
                        .read<CloudScheduleProvider>();
                    final playlistProvider = context.read<PlaylistProvider>();
                    final localVersionProvider = context
                        .read<LocalVersionProvider>();
                    final cipherProvider = context.read<CipherProvider>();
                    final flowItemProvider = context.read<FlowItemProvider>();

                    final domainSchedule = localScheduleProvider.getSchedule(
                      scheduleId,
                    )!;

                    final domainPlaylist = playlistProvider.getPlaylistById(
                      domainSchedule.playlistId!,
                    )!;

                    // Build Item DTOs
                    final flowItems = <String, FlowItem>{};
                    final versions = <String, VersionDto>{};
                    for (var item in domainPlaylist.items) {
                      switch (item.type) {
                        case PlaylistItemType.version:
                          final version = localVersionProvider.getVersion(
                            item.contentId!,
                          );

                          if (version == null) break;
                          final cipher = cipherProvider.getCipherById(
                            version.cipherId,
                          );

                          if (cipher == null) break;
                          versions[item.id.toString()] = version.toDto(cipher);
                          break;
                        case PlaylistItemType.flowItem:
                          final flowItem = flowItemProvider.getFlowItem(
                            item.contentId!,
                          );
                          if (flowItem != null) {
                            flowItems[item.id.toString()] = flowItem;
                          }
                          break;
                      }
                    }

                    cloudScheduleProvider.publishSchedule(
                      domainSchedule.toDto(
                        domainPlaylist.toDto(
                          flowItems: flowItems,
                          versions: versions,
                        ),
                      ),
                    );
                  },
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
                          localScheduleProvider.deleteSchedule(scheduleId);
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

  void _openDuplicateScheduleSheet(BuildContext context, int scheduleId) {
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
