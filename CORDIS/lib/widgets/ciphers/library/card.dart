import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/settings/secret_settings_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/ciphers/library/sheet_actions.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';

class CipherCard extends StatefulWidget {
  final int versionID;

  const CipherCard({super.key, required this.versionID});

  @override
  State<CipherCard> createState() => _CipherCardState();
}

class _CipherCardState extends State<CipherCard> {
  late bool isDense;

  @override
  void initState() {
    super.initState();
    final secSet = context.read<SecretSetProvider>();
    final sect = context.read<SectionProvider>();

    isDense = secSet.denseCipherCard;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await sect.loadSectionsOfVersion(widget.versionID);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();
    final sect = context.read<SectionProvider>();

    if (widget.versionID == -1) {
      return SizedBox.shrink();
    }

    return Consumer2<CipherProvider, LocalVersionProvider>(
      builder: (context, ciph, localVer, child) {
        // Card content
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // Spacing between cards
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerLowest),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Builder(
              builder: (context) {
                final version = localVer.getVersion(widget.versionID);

                if (version == null) {
                  return Center(child: CircularProgressIndicator());
                }

                final cipher = ciph.getCipher(version.cipherID);

                if (cipher == null) {
                  return Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            spacing: 2.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TITLE
                              Text(cipher.title, style: textTheme.titleMedium),

                              // INFO
                              Row(
                                spacing: 16.0,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.musicKey}: ${version.transposedKey ?? cipher.musicKey}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  version.bpm != 0
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.bpmWithPlaceholder(
                                            version.bpm.toString(),
                                          ),
                                          style: textTheme.bodyMedium,
                                        )
                                      : Text('-'),
                                  version.duration != Duration.zero
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.durationWithPlaceholder(
                                            DateTimeUtils.formatDuration(
                                              version.duration,
                                            ),
                                          ),
                                          style: textTheme.bodyMedium,
                                        )
                                      : Text('-'),
                                ],
                              ),

                              // STRUCTURE LIST
                              if (!isDense)
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 25),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: version.songStructure.length,
                                    itemBuilder: (_, index) {
                                      final sect = context
                                          .read<SectionProvider>();

                                      final sectionCode =
                                          version.songStructure[index];

                                      final section = sect.getSection(
                                        widget.versionID,
                                        sectionCode,
                                      );

                                      final color =
                                          section?.contentColor ?? Colors.grey;

                                      // Painter for sections with large codes
                                      final textPainter = TextPainter(
                                        text: TextSpan(
                                          text: sectionCode,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        maxLines: 1,
                                        textDirection: TextDirection.ltr,
                                      )..layout();

                                      return Container(
                                        height: 25,
                                        width: max(
                                          25,
                                          textPainter.size.width + 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          color: color,
                                        ),
                                        margin: const EdgeInsets.only(right: 3),
                                        child: Center(
                                          child: Text(
                                            strutStyle: StrutStyle(
                                              forceStrutHeight: true,
                                            ),
                                            sectionCode,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              // SPACER
                              SizedBox(height: 8),
                            ],
                          ),
                        ),

                        // ACTIONS SHEET
                        IconButton(
                          onPressed: () => _openCipherActionsSheet(cipher.id),
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ),

                    // VIEW / ADD TO PLAYLIST
                    FilledTextButton(
                      text: (sel.isSelectionMode)
                          ? AppLocalizations.of(context)!.addToPlaylist
                          : AppLocalizations.of(context)!.viewPlaceholder(''),
                      isDense: true,
                      onPressed: () async {
                        if (sel.isSelectionMode) {
                          await _createAndAddVersionToPlaylist(version);

                          nav.pop();
                        } else {
                          nav.push(
                            () => ViewCipherScreen(
                              cipherID: cipher.id,
                              versionID: widget.versionID,
                              versionType: VersionType.local,
                            ),
                            showBottomNavBar: true,
                          );
                        }
                      },
                      onLongPress: () async {
                        nav.push(
                          () => EditCipherScreen(
                            cipherID: cipher.id,
                            versionID: widget.versionID,
                            versionType: VersionType.local,
                          ),
                          changeDetector: () {
                            return localVer.hasUnsavedChanges ||
                                sect.hasUnsavedChanges ||
                                ciph.hasUnsavedChanges;
                          },
                          onChangeDiscarded: () {
                            localVer.loadVersion(widget.versionID);
                            ciph.loadCipher(cipher.id);
                            sect.loadSectionsOfVersion(widget.versionID);
                          },
                          showBottomNavBar: true,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _createAndAddVersionToPlaylist(Version version) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final sel = context.read<SelectionProvider>();

    final playlistName = AppLocalizations.of(
      context,
    )!.playlistVersionName(play.getPlaylist(sel.targetId!)!.name);

    final newVersion = version.copyWith(
      versionName: playlistName,
      firebaseID: '',
    );

    localVer.setNewVersionInCache(newVersion);
    final newVersionID = await localVer.createVersion(
      cipherID: version.cipherID,
    );

    if (newVersionID == null) {
      debugPrint('Could not create a copy of version');
      return;
    }

    await sect.loadSectionsOfVersion(version.id!);
    sect.cacheCopyOfVersion(version.id!, newVersionID);
    sect.saveSections(versionID: newVersionID);

    sel.addVersionIdToDelete(newVersionID);

    play.cacheAddVersion(sel.targetId!, newVersionID);
  }

  void _openCipherActionsSheet(int cipherID) {
    final sel = context.read<SelectionProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return CipherCardActionsSheet(
              cipherId: cipherID,
              versionType: sel.isSelectionMode
                  ? VersionType.playlist
                  : VersionType.local,
            );
          },
        );
      },
    );
  }
}
