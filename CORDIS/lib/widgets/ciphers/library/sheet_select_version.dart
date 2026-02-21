import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectVersionSheet extends StatelessWidget {
  final int cipherId;

  const SelectVersionSheet({super.key, required this.cipherId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<NavigationProvider, CipherProvider, LocalVersionProvider>(
      builder:
          (
            context,
            navigationProvider,
            cipherProvider,
            versionProvider,
            child,
          ) {
            final title = cipherProvider.getCipherById(cipherId)?.title;

            if (title == null) {
              return CircularProgressIndicator();
            }

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
                        '${AppLocalizations.of(context)!.selectPlaceholder(AppLocalizations.of(context)!.version)} ${AppLocalizations.of(context)!.belongingTo} $title',
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
                  // VERSIONS
                  ...versionProvider.getVersionsByCipherId(cipherId).map((
                    versionID,
                  ) {
                    return FutureBuilder(
                      future: versionProvider.getVersion(versionID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          return Text('No data');
                        } else {
                          final version = snapshot.data!;
                          return FilledTextButton(
                            text: version.versionName,
                            trailingIcon: Icons.chevron_right,
                            isDiscrete: true,
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(); // Close the bottom sheet
                              navigationProvider.push(
                                ViewCipherScreen(
                                  versionType: VersionType.local,
                                  cipherID: cipherId,
                                  versionID: versionID,
                                ),
                                showBottomNavBar: true,
                              );
                            },
                          );
                        }
                      },
                    );
                  }),
                  SizedBox(),
                ],
              ),
            );
          },
    );
  }
}
