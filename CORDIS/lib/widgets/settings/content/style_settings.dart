import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class StyleSettings extends StatelessWidget {
  const StyleSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LayoutSettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              // HEADER
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.styleSettings,
                    style: textTheme.titleMedium,
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // COLUMN SETTINGS
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: colorScheme.surfaceContainerLowest,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.numberOfColumns,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    for (int i = 1; i <= 3; i++)
                      IconButton(
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            i,
                            (j) => const Icon(Icons.view_column, size: 18),
                          ),
                        ),
                        color: settings.columnCount == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).iconTheme.color,
                        tooltip: '$i coluna${i > 1 ? 's' : ''}',
                        onPressed: () => settings.setColumnCount(i),
                      ),
                  ],
                ),
              ),
              // CHORD COLOR SETTINGS
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: colorScheme.surfaceContainerLowest,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.chordColor,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Color tempColor = settings.chordColor;
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Selecione a cor dos acordes'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: settings.chordColor,
                                  onColorChanged: (color) {
                                    settings.setChordColor(color);
                                  },
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancelar'),
                                  onPressed: () {
                                    settings.setChordColor(tempColor);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: settings.chordColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // FONT SETTINGS
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: colorScheme.surfaceContainerLowest,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: settings.fontFamily,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'OpenSans',
                            child: Text(
                              'OpenSans',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Asimovian',
                            child: Text(
                              'Asimovian',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Asimovian',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Atkinson',
                            child: Text(
                              'Atkinson',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Atkinson',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Caveat',
                            child: Text(
                              'Caveat',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Caveat',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) settings.setFontFamily(v);
                        },
                        underline: Container(),
                      ),
                    ),
                    const SizedBox(width: 32),
                    DropdownButton<double>(
                      value: settings.fontSize,
                      items: List.generate(12, (i) {
                        final double size = 12 + i * 2;
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size.toString()),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) settings.setFontSize(v);
                      },
                      underline: Container(),
                    ),
                  ],
                ),
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
