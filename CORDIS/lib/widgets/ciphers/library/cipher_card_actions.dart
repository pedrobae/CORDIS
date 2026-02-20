import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherCardActionsSheet extends StatelessWidget {
  final int cipherId;
  final VersionType versionType;

  const CipherCardActionsSheet({
    super.key,
    required this.cipherId,
    required this.versionType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<NavigationProvider, CipherProvider, LocalVersionProvider>(
      builder:
          (
            context,
            navigationProvider,
            cipherProvider,
            versionProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;

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
                        style: textTheme.titleMedium,
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
                  // EDIT CIPHER
                  FilledTextButton(
                    text: AppLocalizations.of(
                      context,
                    )!.editPlaceholder(AppLocalizations.of(context)!.cipher),
                    trailingIcon: Icons.chevron_right,
                    isDiscrete: true,
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      navigationProvider.push(
                        EditCipherScreen(
                          versionType: versionType,
                          cipherID: cipherId,
                          isEnabled: versionType == VersionType.local,
                          versionID: versionProvider
                              .getIdOfOldestVersionOfCipher(cipherId),
                        ),
                        showBottomNavBar: true,
                      );
                    },
                  ),
                  // DELETE CIPHER
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.delete,
                    tooltip: AppLocalizations.of(
                      context,
                    )!.deleteCipherDescription,
                    trailingIcon: Icons.chevron_right,
                    isDiscrete: true,
                    isDangerous: true,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return BottomSheet(
                            shape: LinearBorder(),
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(context)!.cipher,
                                onConfirm: () {
                                  cipherProvider.deleteCipher(cipherId);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(),
                ],
              ),
            );
          },
    );
  }
}
