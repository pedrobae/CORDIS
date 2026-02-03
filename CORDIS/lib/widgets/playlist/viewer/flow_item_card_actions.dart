import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowItemCardActionsSheet extends StatelessWidget {
  final int flowItemId;
  final int playlistId;

  const FlowItemCardActionsSheet({
    super.key,
    required this.flowItemId,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<NavigationProvider, FlowItemProvider, PlaylistProvider>(
      builder:
          (
            context,
            navigationProvider,
            flowItemProvider,
            playlistProvider,
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
                  // DUPLICATE FLOW ITEM
                  GestureDetector(
                    onTap: () {
                      flowItemProvider.duplicateFlowItem(
                        flowItemId,
                        AppLocalizations.of(context)!.copySuffix,
                        playlistProvider
                            .getPlaylistById(playlistId)!
                            .items
                            .length,
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
                              AppLocalizations.of(context)!.flowItem,
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
                        builder: (dialogContext) {
                          return BottomSheet(
                            shape: LinearBorder(),
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(
                                  context,
                                )!.flowItem,
                                isDangerous: true,
                                onConfirm: () async {
                                  await flowItemProvider.deleteFlowItem(
                                    flowItemId,
                                  );
                                  await playlistProvider.loadPlaylist(
                                    playlistId,
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
