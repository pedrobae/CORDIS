import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_palette.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_new_section.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_repeat_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/reorderable_structure.dart';
import 'package:cordis/widgets/ciphers/editor/sections/token_content_card.dart';

class SectionsTab extends StatefulWidget {
  final dynamic versionID;
  final VersionType versionType;
  final bool isEnabled;

  const SectionsTab({
    super.key,
    this.versionID,
    required this.versionType,
    this.isEnabled = true,
  });

  @override
  State<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends State<SectionsTab> {
  bool paletteIsOpen = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer4<
      SectionProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            sectionProvider,
            localVersionProvider,
            cloudVersionProvider,
            selectionProvider,
            child,
          ) {
            List<String> uniqueSections;

            switch (widget.versionType) {
              case VersionType.local:
              case VersionType.import:
              case VersionType.playlist:
              case VersionType.brandNew:
                uniqueSections = (localVersionProvider.cachedVersion(
                  widget.versionID ?? -1,
                ))!.songStructure.toSet().toList();
                break;
              case VersionType.cloud:
                uniqueSections = cloudVersionProvider
                    .getVersion(widget.versionID ?? -1)!
                    .songStructure
                    .toSet()
                    .toList();
                break;
            }

            if (sectionProvider.isLoading ||
                localVersionProvider.isLoading ||
                cloudVersionProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 32,
                      children: [
                        // STRUCTURE SECTION
                        Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // LABEL
                                Text(
                                  AppLocalizations.of(context)!.songStructure,
                                  style: textTheme.titleMedium,
                                ),

                                if ((widget.versionID is int &&
                                        localVersionProvider
                                            .cachedVersion(widget.versionID)!
                                            .songStructure
                                            .isNotEmpty) ||
                                    (widget.versionID is String &&
                                        cloudVersionProvider
                                            .getVersion(widget.versionID)!
                                            .songStructure
                                            .isNotEmpty))
                                  // MANAGE SECTION BUTTON
                                  GestureDetector(
                                    onTap: _openRepeatSectionSheet(),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.managePlaceholder(''),
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // DRAGGABLE CHIPS
                            ReorderableStructure(versionId: widget.versionID),
                          ],
                        ),
                        // CONTENT SECTION
                        Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LABEL
                            Text(
                              AppLocalizations.of(context)!.lyrics,
                              style: textTheme.titleMedium,
                            ),

                            // SECTIONS
                            if (uniqueSections.isEmpty)
                              Text(
                                AppLocalizations.of(context)!.noLyrics,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium,
                              )
                            else
                              ...uniqueSections.map((sectionCode) {
                                return TokenContentCard(
                                  versionID: widget.versionID,
                                  sectionCode: sectionCode,
                                  isEnabled: widget.isEnabled,
                                );
                              }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!selectionProvider.isSelectionMode)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      verticalDirection: VerticalDirection.up,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (paletteIsOpen) ...[
                          ChordPalette(versionId: widget.versionID ?? -1),
                        ],
                        // Palette FAB
                        if (widget.isEnabled)
                          GestureDetector(
                            onTap: _togglePalette,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.surfaceContainerLowest,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                paletteIsOpen ? Icons.close : Icons.music_note,
                                size: 28,
                                color: colorScheme.surface,
                              ),
                            ),
                          ),

                        // Open add sheet
                        GestureDetector(
                          onTap: _openAddSheet(),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.surfaceContainerLowest,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              size: 28,
                              color: colorScheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
    );
  }

  VoidCallback _openAddSheet() {
    return () {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return NewSectionSheet(versionId: widget.versionID ?? -1);
        },
      );
    };
  }

  VoidCallback _openRepeatSectionSheet() {
    return () {
      showModalBottomSheet(
        context: context,
        barrierColor: Theme.of(context).colorScheme.onSurface.withAlpha(85),
        isScrollControlled: true,
        builder: (context) {
          return RepeatSectionSheet(versionID: widget.versionID ?? -1);
        },
      );
    };
  }

  void _togglePalette() {
    setState(() {
      paletteIsOpen = !paletteIsOpen;
    });
  }
}
