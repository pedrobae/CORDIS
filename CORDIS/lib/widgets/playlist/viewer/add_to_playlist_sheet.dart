import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/cipher/cipher_library.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final int playlistId;

  const AddToPlaylistSheet({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, SelectionProvider>(
      builder: (context, navigationProvider, selectionProvider, child) {
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
              // ADD SONG TO PLAYLIST
              GestureDetector(
                onTap: () {
                  // Enable selection mode
                  selectionProvider.enableSelectionMode();
                  selectionProvider.setTarget(playlistId);

                  // Close the bottom sheet
                  Navigator.of(context).pop();

                  // Navigate to Cipher Library Screen
                  navigationProvider.push(
                    CipherLibraryScreen(playlistId: playlistId),
                    showAppBar: false,
                    showDrawerIcon: false,
                    onPopCallback: () {
                      // Disable selection mode when returning
                      selectionProvider.disableSelectionMode();
                      selectionProvider.clearTarget();
                    },
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
                        AppLocalizations.of(
                          context,
                        )!.addPlaceholder(AppLocalizations.of(context)!.cipher),
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
              // ADD FLOW ITEM TO PLAYLIST
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  navigationProvider.push(
                    FlowItemEditor(playlistId: playlistId),
                    showAppBar: false,
                    showDrawerIcon: false,
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
                        AppLocalizations.of(context)!.addPlaceholder(
                          AppLocalizations.of(context)!.flowItem,
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.shadow),
                    ],
                  ),
                ),
              ),
              // DELETE PLAYLIST
              GestureDetector(
                onTap: () {},
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
                      Text(
                        AppLocalizations.of(context)!.delete,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                          fontSize: 18,
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
