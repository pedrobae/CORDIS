import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/providers/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistCardActionsSheet extends StatelessWidget {
  final int playlistId;

  const PlaylistCardActionsSheet({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      NavigationProvider,
      PlaylistProvider,
      LocalVersionProvider,
      FlowItemProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            versionProvider,
            flowItemProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;

            // Your widget build logic here
            return Container(
              padding: const EdgeInsets.all(16.0),
              color: colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.quickAction,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  // ACTIONS
                  // RENAME PLAYLIST
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      navigationProvider.push(
                        EditPlaylistScreen(playlistId: playlistId),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.surfaceContainer),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.editPlaceholder(
                              AppLocalizations.of(context)!.playlist,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: colorScheme.shadow),
                        ],
                      ),
                    ),
                  ),
                  // DELETE PLAYLIST
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return BottomSheet(
                            shape: LinearBorder(),
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(
                                  context,
                                )!.playlist,
                                onConfirm: () async {
                                  await _deletePlaylist(
                                    context,
                                    playlistProvider,
                                    versionProvider,
                                    navigationProvider,
                                    flowItemProvider,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.deletePlaylistDescription,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    LocalVersionProvider versionProvider,
    NavigationProvider navigationProvider,
    FlowItemProvider flowItemProvider,
  ) async {
    for (var item in playlistProvider.getPlaylistById(playlistId)!.items) {
      if (item.type == PlaylistItemType.version) {
        await versionProvider.deleteVersion(item.contentId!);
      } else if (item.type == PlaylistItemType.flowItem) {
        await flowItemProvider.deleteFlowItem(item.contentId!);
      }
    }
    await playlistProvider.deletePlaylist(playlistId);
    navigationProvider.pop();
  }
}
