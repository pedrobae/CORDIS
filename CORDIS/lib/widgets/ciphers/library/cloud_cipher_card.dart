import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/selection_provider.dart';

class CloudCipherCard extends StatelessWidget {
  final String versionId;
  final int? playlistId;

  const CloudCipherCard({super.key, required this.versionId, this.playlistId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<
      SelectionProvider,
      NavigationProvider,
      CloudVersionProvider
    >(
      builder:
          (
            context,
            selectionProvider,
            navigationProvider,
            cloudVersionProvider,
            child,
          ) {
            final version = cloudVersionProvider.getVersion(versionId)!;

            return GestureDetector(
              onTap: () {
                if (selectionProvider.isSelectionMode) {
                  selectionProvider.select(versionId);
                  navigationProvider.push(
                    EditCipherScreen(
                      versionType: VersionType.playlist,
                      playlistID: selectionProvider.targetId!,
                      isEnabled: false,
                      versionID: versionId,
                    ),
                  );
                } else {
                  navigationProvider.push(
                    ViewCipherScreen(
                      cipherId: null,
                      versionId: versionId,
                      versionType: VersionType.cloud,
                    ),
                    showAppBar: false,
                    showDrawerIcon: false,
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
                          Text(version.title, style: textTheme.titleMedium),
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.musicKey}: ${version.transposedKey ?? version.originalKey}',
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
                              version.duration > 0
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.durationWithPlaceholder(
                                        DateTimeUtils.formatDuration(
                                          Duration(seconds: version.duration),
                                        ),
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                            ],
                          ),
                          Text(
                            AppLocalizations.of(context)!.cloudCipher,
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ACTIONS
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.amberAccent,
                            content: Text(
                              AppLocalizations.of(context)!.comingSoon,
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.cloud_download),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
