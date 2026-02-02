import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/library/cipher_card_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherCard extends StatefulWidget {
  final int cipherId;
  final int? playlistId;

  const CipherCard({super.key, required this.cipherId, this.playlistId});

  @override
  State<CipherCard> createState() => _CipherCardState();
}

class _CipherCardState extends State<CipherCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalVersionProvider>().loadVersionsOfCipher(
        widget.cipherId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer5<
      CipherProvider,
      LocalVersionProvider,
      SelectionProvider,
      PlaylistProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            selectionProvider,
            playlistProvider,
            navigationProvider,
            child,
          ) {
            // Error handling
            if (cipherProvider.error != null || versionProvider.error != null) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.errorMessage(
                    AppLocalizations.of(context)!.loading,
                    cipherProvider.error ?? versionProvider.error!,
                  ),
                ),
              );
            }

            final cipher = cipherProvider.getCipherById(widget.cipherId)!;
            final versionCount = versionProvider.getVersionsOfCipherCount(
              widget.cipherId,
            );

            final versionId = versionProvider.getIdOfOldestVersionOfCipher(
              widget.cipherId,
            );

            if (versionId == null) {
              return Container();
            }

            // Loading state
            if (cipherProvider.isLoading || versionProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final version = versionProvider.getVersion(versionId)!;

            // Card content
            return GestureDetector(
              onTap: () {
                if (selectionProvider.isSelectionMode) {
                  try {
                    selectionProvider.select(versionId);
                    navigationProvider.push(
                      EditCipherScreen(
                        cipherID: widget.cipherId,
                        versionID: versionId,
                        versionType: VersionType.playlist,
                        playlistID: widget.playlistId,
                      ),
                      showAppBar: false,
                      showDrawerIcon: false,
                      onPopCallback: () {
                        selectionProvider.deselect(versionId);
                        selectionProvider.enableSelectionMode();
                      },
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.errorMessage(
                            AppLocalizations.of(context)!.addToPlaylist,
                            error.toString(),
                          ),
                        ),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                } else {
                  navigationProvider.push(
                    ViewCipherScreen(
                      cipherId: widget.cipherId,
                      versionId: versionProvider.getIdOfOldestVersionOfCipher(
                        widget.cipherId,
                      ),
                      versionType: VersionType.local,
                    ),
                    showAppBar: false,
                    showDrawerIcon: false,
                  );
                }
              },
              onLongPress: () async {
                if (!selectionProvider.isSelectionMode) {
                  navigationProvider.push(
                    EditCipherScreen(
                      cipherID: widget.cipherId,
                      versionID: versionProvider.getIdOfOldestVersionOfCipher(
                        widget.cipherId,
                      ),
                      versionType: VersionType.local,
                    ),
                  );
                } else {
                  selectionProvider.select(
                    versionProvider.getIdOfOldestVersionOfCipher(
                      widget.cipherId,
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.surfaceContainerLowest),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // INFO
                    Expanded(
                      child: Column(
                        spacing: 2.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cipher.title, style: textTheme.titleMedium),
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.musicKey}: ${cipher.musicKey}',
                                style: textTheme.bodyMedium,
                              ),
                              version.bpm != 0
                                  ? Text(
                                      version.bpm.toString(),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                              version.duration != Duration.zero
                                  ? Text(
                                      DateTimeUtils.formatDuration(
                                        version.duration,
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                            ],
                          ),
                          Text(
                            '$versionCount${AppLocalizations.of(context)!.versions}',
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ACTIONS
                    IconButton(
                      onPressed: () =>
                          _openCipherActionsSheet(context, selectionProvider),
                      icon: Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  void _openCipherActionsSheet(
    BuildContext context,
    SelectionProvider selectionProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return CipherCardActionsSheet(
              cipherId: widget.cipherId,
              versionType: selectionProvider.isSelectionMode
                  ? VersionType.playlist
                  : VersionType.local,
            );
          },
        );
      },
    );
  }
}
