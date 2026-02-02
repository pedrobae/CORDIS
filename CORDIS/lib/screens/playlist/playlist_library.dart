import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/playlist/library/playlist_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/playlist_provider.dart';

class PlaylistLibraryScreen extends StatefulWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  State<PlaylistLibraryScreen> createState() => _PlaylistLibraryScreenState();
}

class _PlaylistLibraryScreenState extends State<PlaylistLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlaylistProvider>().loadPlaylists();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer3<PlaylistProvider, NavigationProvider, SelectionProvider>(
      builder:
          (
            context,
            playlistProvider,
            navigationProvider,
            selectionProvider,
            child,
          ) {
            final isSelecting = selectionProvider.isSelectionMode;

            return Stack(
              children: [
                Padding(
                  padding: isSelecting
                      ? EdgeInsets.zero
                      : EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16.0,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchPlaylist,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: colorScheme.surfaceContainer,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.search),
                          fillColor: colorScheme.surfaceContainerHighest,
                          visualDensity: VisualDensity.compact,
                        ),
                        onChanged: (value) {
                          playlistProvider.setSearchTerm(value);
                        },
                      ),

                      Expanded(child: PlaylistScrollView()),
                    ],
                  ),
                ),
                if (!isSelecting)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () =>
                          navigationProvider.push(EditPlaylistScreen()),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.onSurface,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.surfaceContainerLowest,
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add, color: colorScheme.surface),
                      ),
                    ),
                  ),
              ],
            );
          },
    );
  }
}
