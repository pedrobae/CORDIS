import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/screens/schedule/edit_schedule.dart';
import 'package:cordis/screens/schedule/play_schedule.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewScheduleScreen extends StatefulWidget {
  final dynamic scheduleId;

  const ViewScheduleScreen({super.key, required this.scheduleId});

  @override
  State<ViewScheduleScreen> createState() => _ViewScheduleScreenState();
}

class _ViewScheduleScreenState extends State<ViewScheduleScreen> {
  late bool isCloud;

  @override
  void initState() {
    super.initState();
    isCloud = widget.scheduleId is String;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      LocalScheduleProvider,
      CloudScheduleProvider,
      PlaylistProvider,
      NavigationProvider,
      SelectionProvider,
      UserProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            playlistProvider,
            navigationProvider,
            selectionProvider,
            userProvider,
            child,
          ) {
            // LOADING STATE
            if (localScheduleProvider.isLoading ||
                cloudScheduleProvider.isLoading) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.loading),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.pop();
                    },
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            // ERROR STATE
            if (localScheduleProvider.error != null &&
                cloudScheduleProvider.error != null) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.error),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.pop();
                    },
                  ),
                ),
                body: Center(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.errorMessage(
                          AppLocalizations.of(context)!.load,
                          localScheduleProvider.error ??
                              cloudScheduleProvider.error ??
                              '',
                        ),
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          localScheduleProvider.loadSchedules();
                          cloudScheduleProvider.loadSchedules(
                            context.read<MyAuthProvider>().id!,
                          );
                        },
                        child: Text(AppLocalizations.of(context)!.tryAgain),
                      ),
                    ],
                  ),
                ),
              );
            }

            // FETCH SCHEDULE DEPENDING ON PROVIDER
            final dynamic schedule = isCloud
                ? cloudScheduleProvider.getSchedule(widget.scheduleId)
                : localScheduleProvider.getSchedule(widget.scheduleId);

            if (schedule == null) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.scheduleNotFound),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.pop();
                    },
                  ),
                ),
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.scheduleNotFoundMessage,
                  ),
                ),
              );
            }

            final playlist = schedule is Schedule
                ? playlistProvider.getPlaylistById(schedule.playlistId!)
                : (schedule as ScheduleDto).playlist.toDomain(
                    userProvider.getLocalIdByFirebaseId(
                      schedule.ownerFirebaseId,
                    )!,
                  );

            int memberCount = 0;
            for (var role in schedule.roles) {
              memberCount += role.memberIds.length as int;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(schedule.name),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.pop();
                  },
                ),
                actions: [
                  // PLAY MODE
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: () {
                      navigationProvider.push(
                        PlayScheduleScreen(scheduleId: widget.scheduleId),
                        showAppBar: false,
                        showDrawerIcon: false,
                        showBottomNavBar: false,
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.surfaceContainerLowest,
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    spacing: 28,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        colorScheme,
                        AppLocalizations.of(context)!.scheduleDetails,
                        [
                          Text(
                            schedule.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            spacing: 16,
                            children: [
                              Text(
                                DateTimeUtils.formatDate(
                                  (schedule is Schedule)
                                      ? schedule.date
                                      : (schedule as ScheduleDto).datetime
                                            .toDate(),
                                ),
                              ),
                              Text(
                                (schedule is Schedule)
                                    ? schedule.time.format(context)
                                    : '${schedule.datetime.toDate().hour.toString().padLeft(2, '0')}:${ //
                                      schedule.datetime.toDate().minute.toString().padLeft(2, '0')}',
                              ),
                              Text(schedule.location),
                            ],
                          ),
                          FilledTextButton(
                            text: AppLocalizations.of(context)!.editPlaceholder(
                              AppLocalizations.of(context)!.scheduleDetails,
                            ),
                            isDark: true,
                            isDense: true,
                            onPressed: () {
                              navigationProvider.push(
                                EditScheduleScreen(
                                  mode: EditScheduleMode.details,
                                  scheduleId: widget.scheduleId,
                                ),
                                showAppBar: false,
                                showDrawerIcon: false,
                              );
                            },
                          ),
                        ],
                      ),

                      // PLAYLIST SECTION
                      _buildSectionCard(
                        colorScheme,
                        AppLocalizations.of(context)!.playlist,
                        [
                          if (playlist == null) ...[
                            Text(
                              AppLocalizations.of(context)!.noPlaylistAssigned,
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            FilledTextButton(
                              text: AppLocalizations.of(
                                context,
                              )!.schedulePlaylist,
                              onPressed: () {
                                selectionProvider.enableSelectionMode(
                                  targetId: widget.scheduleId,
                                );
                                navigationProvider.push(
                                  EditScheduleScreen(
                                    mode: EditScheduleMode.playlist,
                                    scheduleId: widget.scheduleId,
                                  ),
                                  showAppBar: false,
                                  showDrawerIcon: false,
                                  onPopCallback: () =>
                                      selectionProvider.disableSelectionMode(),
                                );
                              },
                              isDense: true,
                              isDark: true,
                            ),
                          ] else ...[
                            Text(
                              playlist.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              spacing: 16,
                              children: [
                                Text(
                                  (playlist.items.length == 1)
                                      ? '1 ${AppLocalizations.of(context)!.item}'
                                      : '${playlist.items.length} ${AppLocalizations.of(context)!.pluralPlaceholder(
                                          AppLocalizations.of(context)!.item, //
                                        )}',
                                ),
                                Text(
                                  '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(playlist.getTotalDuration())}',
                                ),
                              ],
                            ),
                            FilledTextButton(
                              text: AppLocalizations.of(
                                context,
                              )!.changePlaylist,
                              isDark: true,
                              isDense: true,
                              onPressed: () {
                                if (isCloud) return;
                                selectionProvider.enableSelectionMode(
                                  targetId: widget.scheduleId,
                                );
                                selectionProvider.select(
                                  localScheduleProvider
                                      .getSchedule(widget.scheduleId)!
                                      .playlistId,
                                );

                                navigationProvider.push(
                                  EditScheduleScreen(
                                    mode: EditScheduleMode.playlist,
                                    scheduleId: widget.scheduleId,
                                  ),
                                  showAppBar: false,
                                  showDrawerIcon: false,
                                  onPopCallback: () =>
                                      selectionProvider.disableSelectionMode(),
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      // MEMBERS SECTION
                      _buildSectionCard(
                        colorScheme,
                        '${AppLocalizations.of(context)!.role} & ${ //
                        AppLocalizations.of(context)!.pluralPlaceholder(
                          AppLocalizations.of(context)!.member, //
                        )}',
                        [
                          Text(
                            AppLocalizations.of(context)!.pluralPlaceholder(
                              AppLocalizations.of(context)!.role,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            spacing: 16,
                            children: [
                              Text(
                                (schedule.roles.length == 1)
                                    ? '1 ${AppLocalizations.of(context)!.role}'
                                    : '${schedule.roles.length} ${AppLocalizations.of(context)!.pluralPlaceholder(
                                        AppLocalizations.of(context)!.role, //
                                      )}',
                              ),
                              Text(
                                (memberCount == 1)
                                    ? '1 ${AppLocalizations.of(context)!.member}'
                                    : '$memberCount ${AppLocalizations.of(context)!.pluralPlaceholder(
                                        AppLocalizations.of(context)!.member, //
                                      )}',
                              ),
                            ],
                          ),
                          FilledTextButton(
                            text: AppLocalizations.of(
                              context,
                            )!.editPlaceholder(''),
                            isDark: true,
                            isDense: true,
                            onPressed: () {
                              navigationProvider.push(
                                EditScheduleScreen(
                                  mode: EditScheduleMode.roleMember,
                                  scheduleId: widget.scheduleId,
                                ),
                                showAppBar: false,
                                showDrawerIcon: false,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  Widget _buildSectionCard(
    ColorScheme colorScheme,
    String label,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
