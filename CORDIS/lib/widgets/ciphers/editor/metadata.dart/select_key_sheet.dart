import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class SelectKeySheet extends StatelessWidget {
  final TextEditingController controller;

  const SelectKeySheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final keys = context.read<LayoutSettingsProvider>().keys;

    final selectedKey = controller.text;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      height: MediaQuery.of(context).size.height / 3,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.keyHint,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CloseButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          Expanded(
            child: MasonryGridView.builder(
              itemCount: keys.length,
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemBuilder: (BuildContext context, int index) {
                final key = keys[index];
                return GestureDetector(
                  onTap: () {
                    controller.text = key;
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: key == selectedKey
                          ? colorScheme.onSurface
                          : colorScheme.surface,
                      border: Border.all(
                        color: colorScheme.onSurface,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      key,
                      style: textTheme.bodyMedium?.copyWith(
                        color: key == selectedKey
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
