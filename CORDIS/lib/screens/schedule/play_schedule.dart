import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/schedule/play/play_cloud_version.dart';
import 'package:cordis/widgets/schedule/play/play_flow_item.dart';
import 'package:cordis/widgets/schedule/play/play_local_version.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayScheduleScreen extends StatefulWidget {
  final dynamic scheduleId;

  const PlayScheduleScreen({super.key, required this.scheduleId});

  @override
  State<PlayScheduleScreen> createState() => PlayScheduleScreenState();
}

class PlayScheduleScreenState extends State<PlayScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final bool isCloud = widget.scheduleId is String;

  bool isPlaying = false;

  int currentTabIndex = 0;
  List<PlaylistItem> items = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDataLoaded();
    });
    super.initState();
  }

  Future<void> _ensureDataLoaded() async {
    final scheduleProvider = context.read<LocalScheduleProvider>();
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final cipherProvider = context.read<CipherProvider>();
    final versionProvider = context.read<LocalVersionProvider>();
    final flowItemProvider = context.read<FlowItemProvider>();

    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;

      await playlistProvider.loadPlaylist(schedule.playlistId!);

      items = playlistProvider.getPlaylistById(schedule.playlistId!)!.items;

      for (final item in items) {
        if (item.type == PlaylistItemType.version) {
          await versionProvider.loadVersion(item.contentId!);
          await cipherProvider.loadCipherOfVersion(item.contentId!);
        } else if (item.type == PlaylistItemType.flowItem) {
          await flowItemProvider.loadFlowItem(item.contentId!);
        }
      }
    } else {
      if (!cloudScheduleProvider.schedules.containsKey(widget.scheduleId)) {
        await cloudScheduleProvider.loadSchedule(widget.scheduleId);
      }

      final schedule = cloudScheduleProvider.schedules[widget.scheduleId];

      if (schedule == null) {
        throw Exception("Schedule not found");
      }
      setState(() {
        items = schedule.playlist.getPlaylistItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CloudScheduleProvider,
      PlaylistProvider,
      LocalVersionProvider,
      CipherProvider,
      FlowItemProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            scheduleProvider,
            playlistProvider,
            versionProvider,
            cipherProvider,
            flowItemProvider,
            navigationProvider,
            child,
          ) {
            String nextTitle = '';
            if (currentTabIndex + 1 < items.length) {
              final nextItem = items[currentTabIndex + 1];
              if (nextItem.type == PlaylistItemType.version) {
                if (isCloud) {
                  nextTitle =
                      ((scheduleProvider.schedules[widget.scheduleId]
                              as ScheduleDto)
                          .playlist
                          .versions[nextItem.firebaseContentId]
                          ?.title) ??
                      '';
                } else {
                  nextTitle =
                      cipherProvider.getCipherById(nextItem.id!)?.title ?? '';
                }
              } else if (nextItem.type == PlaylistItemType.flowItem) {
                if (isCloud) {
                  nextTitle =
                      ((scheduleProvider.schedules[widget.scheduleId]
                              as ScheduleDto)
                          .playlist
                          .flowItems[nextItem.firebaseContentId]?['title']) ??
                      '';
                } else {
                  nextTitle =
                      flowItemProvider.getFlowItem(nextItem.id!)?.title ?? '';
                }
              }
            }
            return Stack(
              children: [
                // TAB VIEWER
                items.isEmpty
                    ? (versionProvider.isLoading ||
                              scheduleProvider.isLoading ||
                              flowItemProvider.isLoading ||
                              cipherProvider.isLoading ||
                              playlistProvider.isLoading)
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : Center(
                              child: Text(
                                AppLocalizations.of(context)!.noPlaylistItems,
                                style: textTheme.bodyMedium,
                              ),
                            )
                    : Builder(
                        builder: (context) {
                          final item = items[currentTabIndex];
                          switch (item.type) {
                            case PlaylistItemType.version:
                              if (isCloud) {
                                return PlayCloudVersion(
                                  versionDTO:
                                      (scheduleProvider.schedules[widget
                                                  .scheduleId]
                                              as ScheduleDto)
                                          .playlist
                                          .versions[item.firebaseContentId]!,
                                );
                              } else {
                                // Local version play
                                return PlayLocalVersion(
                                  versionId: item.contentId!,
                                );
                              }
                            case PlaylistItemType.flowItem:
                              if (isCloud) {
                                final flowItemMap =
                                    (scheduleProvider.schedules[widget
                                                .scheduleId]
                                            as ScheduleDto)
                                        .playlist
                                        .flowItems[item.firebaseContentId]!;

                                return PlayFlowItem(
                                  flowItem: FlowItem(
                                    firebaseId: item.firebaseContentId!,
                                    playlistId: -1,
                                    title: flowItemMap['title'] as String,
                                    contentText:
                                        flowItemMap['contentText'] as String,
                                    duration: Duration(
                                      seconds: (flowItemMap['duration'] as int),
                                    ),
                                    position: flowItemMap['position'] as int,
                                  ),
                                );
                              } else {
                                return PlayFlowItem(
                                  flowItem: flowItemProvider.getFlowItem(
                                    item.id!,
                                  )!,
                                );
                              }
                          }
                        },
                      ),

                // TOP RIGHT CLOSE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => navigationProvider.pop(),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.close,
                        color: colorScheme.shadow,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // BOTTOM PLAY CONTROLS
                Positioned(
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(0),
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.surfaceContainerHigh,
                          width: .5,
                        ),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PREVIOUS ITEM BUTTON
                        GestureDetector(
                          onTap: () {
                            if (currentTabIndex > 0) {
                              setState(() {
                                currentTabIndex--;
                              });
                            }
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 48,
                            child: Icon(
                              Icons.chevron_left,
                              color: colorScheme.shadow,
                              size: 48,
                            ),
                          ),
                        ),

                        // NEXT ITEM TITLE
                        Text(
                          nextTitle.isEmpty
                              ? '-'
                              : AppLocalizations.of(
                                  context,
                                )!.nextPlaceholder(nextTitle),
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.shadow,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // NEXT ITEM BUTTON
                        GestureDetector(
                          onTap: () {
                            if (currentTabIndex < items.length - 1) {
                              setState(() {
                                currentTabIndex++;
                              });
                            }
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 48,
                            child: Icon(
                              Icons.chevron_right,
                              color: colorScheme.shadow,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }
}
