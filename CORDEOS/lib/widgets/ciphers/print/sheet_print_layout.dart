import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrintLayout extends StatefulWidget {
  const PrintLayout({super.key});

  @override
  State<PrintLayout> createState() => _PrintLayoutState();
}

class _PrintLayoutState extends State<PrintLayout> {
  late double heightSpacing;
  late double letterSpacing;

  late double margin;
  late double sectionSpacing;
  late double headerGap;
  late double columnGap;
  late int columnCount;

  @override
  void initState() {
    final print = context.read<PrintingProvider>();

    heightSpacing = print.heightSpacing.clamp(0, 10);
    letterSpacing = print.letterSpacing.clamp(-2, 2);

    margin = print.margin.clamp(5, 50);
    sectionSpacing = print.sectionSpacing.clamp(5, 50);
    headerGap = print.headerGap.clamp(5, 50);
    columnGap = print.columnGap.clamp(5, 50);
    columnCount = print.columnCount;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final print = context.read<PrintingProvider>();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Container(
        color: colorScheme.surface,
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
                  AppLocalizations.of(context)!.layoutSettings,
                  style: textTheme.titleMedium,
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    _buildToggle(
                      context,
                      label: l10n.hasColumns,
                      value: columnCount == 2,
                      onChanged: (_) async {
                        setState(() {
                          columnCount = columnCount == 1 ? 2 : 1;
                        });
                        await print.toggleColumnCount();
                      },
                    ),
                    _buildSlider(
                      value: heightSpacing,
                      label: l10n.heightSpacing,
                      minValue: 0,
                      maxValue: 10,
                      onChanged: (v) => setState(() => heightSpacing = v),
                      onChangeEnd: (v) async {
                        await print.setHeightSpacing(v);
                      },
                    ),
              
                    _buildSlider(
                      value: letterSpacing,
                      label: l10n.letterSpacing,
                      minValue: -3,
                      maxValue: 3,
                      onChanged: (v) => setState(() => letterSpacing = v),
                      onChangeEnd: (v) async {
                        await print.setLetterSpacing(v);
                      },
                    ),
                    // PAGE LAYOUT SETTINGS
                    _buildSlider(
                      value: margin,
                      label: l10n.margin,
                      minValue: 5,
                      maxValue: 50,
                      onChanged: (v) => setState(() => margin = v),
                      onChangeEnd: (v) async {
                        await print.setMargin(v);
                      },
                    ),
                    _buildSlider(
                      value: sectionSpacing,
                      label: l10n.sectionSpacing,
                      minValue: 0,
                      maxValue: 40,
                      onChanged: (v) => setState(() => sectionSpacing = v),
                      onChangeEnd: (v) async {
                        await print.setSectionSpacing(v);
                      },
                    ),
                    _buildSlider(
                      value: headerGap,
                      label: l10n.headerGap,
                      minValue: 0,
                      maxValue: 30,
                      onChanged: (v) => setState(() => headerGap = v),
                      onChangeEnd: (v) async {
                        await print.setHeaderGap(v);
                      },
                    ),
                    _buildSlider(
                      value: columnGap,
                      label: l10n.columnGap,
                      minValue: 0,
                      maxValue: 40,
                      onChanged: (v) => setState(() => columnGap = v),
                      onChangeEnd: (v) async {
                        await print.setColumnGap(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox()
          ],
        ),
      ),
    );
  }

  Row _buildToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(Icons.chevron_right),
        Expanded(child: Text(label, style: textTheme.labelLarge)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Container _buildSlider({
    required double value,
    required String label,
    required double minValue,
    required double maxValue,
    required void Function(double) onChanged,
    required Function(double) onChangeEnd,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: colorScheme.surfaceContainerLowest, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.labelLarge)),
          Text(
            value.toStringAsFixed(1),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 150,
            child: Slider(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              value: value,
              divisions: ((maxValue - minValue) * 10).toInt(),
              min: minValue,
              max: maxValue,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}
