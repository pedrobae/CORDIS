import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VersionCardActionsSheet extends StatelessWidget {
  final int versionId;
  final int playlistId;

  const VersionCardActionsSheet({
    super.key,
    required this.versionId,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer5<
      NavigationProvider,
      PlaylistProvider,
      LocalVersionProvider,
      UserProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            versionProvider,
            userProvider,
            authProvider,
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
                  // DUPLICATE VERSION
                  GestureDetector(
                    onTap: () {
                      playlistProvider.duplicateVersion(
                        playlistId,
                        versionId,
                        userProvider.getLocalIdByFirebaseId(authProvider.id!)!,
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
                            AppLocalizations.of(context)!.duplicatePlaceholder(
                              AppLocalizations.of(context)!.version,
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
                  // DELETE FLOW ITEM
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return BottomSheet(
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(context)!.version,
                                isDangerous: true,
                                onConfirm: () async {
                                  playlistProvider.removeVersionFromPlaylist(
                                    versionId,
                                    playlistId,
                                  );
                                  await versionProvider.deleteVersion(
                                    versionId,
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
}
