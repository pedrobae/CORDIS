import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/screens/cipher/import/import_pdf.dart';
import 'package:cordis/screens/cipher/import/import_text.dart';
import 'package:cordis/widgets/ciphers/editor/sections/select_type.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewSectionSheet extends StatelessWidget {
  final bool secret;
  final int versionId;
  const NewSectionSheet({super.key, this.secret = false, this.versionId = -1});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          /// ADD SECTION BUTTON
          if (!secret)
            FilledTextButton(
              text: AppLocalizations.of(
                context,
              )!.newPlaceholder(AppLocalizations.of(context)!.section),
              isDark: true,
              icon: Icons.add,
              trailingIcon: Icons.chevron_right,
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NavigationProvider>().pushForeground(
                  SelectType(
                    sectionCode: null,
                    versionID: versionId,
                    isNewSection: true,
                  ),
                );
              },
            ),

          /// IMPORT SECTION BUTTONS
          if (secret)
            FilledTextButton(
              text: AppLocalizations.of(context)!.importFromText,
              icon: Icons.text_snippet,
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NavigationProvider>().push(
                  const ImportTextScreen(),
                );
              },
            ),
          FilledTextButton(
            text: AppLocalizations.of(context)!.importFromPDF,
            icon: Icons.picture_as_pdf,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavigationProvider>().push(const ImportPdfScreen());
            },
          ),
          if (secret)
            FilledTextButton(
              text: AppLocalizations.of(context)!.importFromImage,
              icon: Icons.image,
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
              onPressed: () {
                // for now show coming soon snackbar from the settings screen
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.amberAccent,
                    content: Text(
                      'Funcionalidade em desenvolvimento,',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
}
