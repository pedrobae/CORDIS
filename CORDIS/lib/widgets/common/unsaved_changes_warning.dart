import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

class UnsavedChangesWarning extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onCancel;

  const UnsavedChangesWarning({
    super.key,
    required this.onDiscard,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          // HEADER
          Text(
            AppLocalizations.of(context)!.unsavedChangesTitle,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          // MESSAGE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              AppLocalizations.of(context)!.unsavedChangesMessage,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          // ACTIONS
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledTextButton(
                text: AppLocalizations.of(context)!.leaveWithoutSaving,
                onPressed: onDiscard,
                isDark: true,
              ),
              FilledTextButton(
                text: AppLocalizations.of(context)!.stayOnPage,
                onPressed: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
