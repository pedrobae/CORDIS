import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrintFilters extends StatefulWidget {
  const PrintFilters({super.key});

  @override
  State<PrintFilters> createState() => _PrintFiltersState();
}

class _PrintFiltersState extends State<PrintFilters> {
  late bool showHeader;
  late bool showRepeatSections;
  late bool showAnnotations;
  late bool showSongMap;
  late bool showSectionLabels;
  late bool showBpm;
  late bool showDuration;

  @override
  void initState() {
    final print = context.read<PrintingProvider>();

    showHeader = print.showHeader;
    showRepeatSections = print.showRepeatSections;
    showAnnotations = print.showAnnotations;
    showSongMap = print.showSongMap;
    showSectionLabels = print.showSectionLabels;
    showBpm = print.showBpm;
    showDuration = print.showDuration;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final print = context.read<PrintingProvider>();

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
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
                  AppLocalizations.of(context)!.contentFilters,
                  style: textTheme.titleMedium,
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            _buildFilterToggle(
              context,
              label: l10n.header,
              value: showHeader,
              onChanged: (_) async {
                setState(() {
                  showHeader = !showHeader;
                });
                await print.toggleHeader();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.songStructure,
              value: showSongMap,
              onChanged: (_) async {
                setState(() {
                  showSongMap = !showSongMap;
                });
                await print.toggleSongMap();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.bpm,
              value: showBpm,
              onChanged: (_) async {
                setState(() {
                  showBpm = !showBpm;
                });
                await print.toggleBpm();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.duration,
              value: showDuration,
              onChanged: (_) async {
                setState(() {
                  showDuration = !showDuration;
                });
                await print.toggleDuration();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.sectionLabels,
              value: showSectionLabels,
              onChanged: (_) async {
                setState(() {
                  showSectionLabels = !showSectionLabels;
                });
                await print.toggleSectionLabels();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.repeatSections,
              value: showRepeatSections,
              onChanged: (_) async {
                setState(() {
                  showRepeatSections = !showRepeatSections;
                });
                await print.toggleRepeatSections();
              },
            ),
            _buildFilterToggle(
              context,
              label: l10n.annotations,
              value: showAnnotations,
              onChanged: (_) async {
                setState(() {
                  showAnnotations = !showAnnotations;
                });
                await print.toggleAnnotations();
              },
            ),
            SizedBox(),
          ],
        ),
      ),
    );
  }

  Row _buildFilterToggle(
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
}
