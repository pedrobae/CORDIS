import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';

import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/widgets/playlist/viewer/add_to_playlist_sheet.dart';

import 'package:cordis/widgets/playlist/viewer/version_card.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPlaylistScreen extends StatefulWidget {
  final int playlistId; // Receive the playlist ID from the parent

  const ViewPlaylistScreen({super.key, required this.playlistId});

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playlistProvider = context.read<PlaylistProvider>();
      final versionProvider = context.read<LocalVersionProvider>();
      final flowItemProvider = context.read<FlowItemProvider>();

      await playlistProvider.loadPlaylist(widget.playlistId);

      // Load versions for the playlist items
      final items =
          playlistProvider.getPlaylistById(widget.playlistId)?.items ?? [];

      for (var item in items) {
        if (item.type == PlaylistItemType.version) {
          await versionProvider.loadVersion(item.contentId!);
        } else if (item.type == PlaylistItemType.flowItem) {
          await flowItemProvider.loadFlowItem(item.contentId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer5<
      PlaylistProvider,
      UserProvider,
      MyAuthProvider,
      NavigationProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            playlistProvider,
            userProvider,
            authProvider,
            navigationProvider,
            selectionProvider,
            child,
          ) {
            final playlist = playlistProvider.getPlaylistById(
              widget.playlistId,
            );
            // Handle loading state
            if (playlist == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              appBar: AppBar(
                leading: BackButton(color: colorScheme.onSurface),
                title: Text(
                  playlist.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  _openPlaylistEditSheet(context);
                },
                backgroundColor: colorScheme.onSurface,
                shape: const CircleBorder(),
                child: Icon(Icons.add, color: colorScheme.onPrimary),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: playlist.items.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.emptyPlaylist,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.emptyPlaylistInstructions,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    // ITEMS LIST
                    : Builder(
                        builder: (context) {
                          return ReorderableListView.builder(
                            shrinkWrap: true,
                            proxyDecorator: (child, index, animation) =>
                                Material(
                                  type: MaterialType.transparency,
                                  child: child,
                                ),
                            buildDefaultDragHandles: false,
                            physics: const ClampingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            onReorder: (oldIndex, newIndex) => _onReorder(
                              context,
                              playlist,
                              oldIndex,
                              newIndex,
                            ),
                            itemCount: playlist.items.length,
                            itemBuilder: (BuildContext context, int index) {
                              final playlistItem = playlist.items[index];

                              switch (playlistItem.type) {
                                case PlaylistItemType.version:
                                  return PlaylistVersionCard(
                                    key: ValueKey(
                                      'playlist_version_${playlistItem.id}',
                                    ),
                                    index: playlistItem.position,
                                    versionId: playlistItem.contentId,
                                    playlistId: widget.playlistId,
                                  );
                                case PlaylistItemType.flowItem:
                                  return FlowItemCard(
                                    key: ValueKey(
                                      'flow_item_${playlistItem.id}',
                                    ),
                                    flowItemId:
                                        playlistItem.contentId ??
                                        playlistItem.id!,
                                    playlistId: widget.playlistId,
                                  );
                              }
                            },
                          );
                        },
                      ),
              ),
            );
          },
    );
  }

  void _openPlaylistEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (BuildContext context) {
            return AddToPlaylistSheet(playlistId: widget.playlistId);
          },
        );
      },
    );
  }

  void _onReorder(
    BuildContext context,
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      await context.read<PlaylistProvider>().reorderItems(
        oldIndex,
        newIndex,
        playlist,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reordenar: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () =>
                  _onReorder(context, playlist, oldIndex, newIndex),
            ),
          ),
        );
      }
    }
  }
}
