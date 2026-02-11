import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_palette.dart';
import 'package:cordis/widgets/ciphers/editor/new_section_sheet.dart';
import 'package:cordis/widgets/filled_text_button.dart';
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
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
                                    onTap: () {
                                      _showRepeatSectionSheet(
                                        context,
                                        sectionProvider,
                                        localVersionProvider,
                                        cloudVersionProvider,
                                      );
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.managePlaceholder(''),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),

                            // SECTIONS
                            if (uniqueSections.isEmpty)
                              Text(
                                AppLocalizations.of(context)!.noLyrics,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colorScheme.onSurface),
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
                          ChordPalette(
                            versionId: widget.versionID ?? -1,
                            onClose: _togglePalette,
                          ),
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
                                paletteIsOpen ? Icons.close : Icons.palette,
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

  void _showRepeatSectionSheet(
    BuildContext context,
    SectionProvider sectionProvider,
    LocalVersionProvider localVersionProvider,
    CloudVersionProvider cloudVersionProvider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final List<String> songStructure;

    if (widget.versionID is int) {
      songStructure = localVersionProvider
          .cachedVersion(widget.versionID ?? -1)!
          .songStructure;
    } else {
      songStructure = cloudVersionProvider
          .getVersion(widget.versionID ?? -1)!
          .songStructure;
    }

    showModalBottomSheet(
      context: context,
      barrierColor: colorScheme.onSurface.withAlpha(85),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.only(
            bottom: 24,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              spacing: 16,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.duplicatePlaceholder(
                            AppLocalizations.of(context)!.section,
                          ),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.duplicateSectionInstruction,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.surfaceContainerLowest,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.topRight,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),

                // EXISTING SECTIONS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var sectionCode in songStructure.toSet())
                      Builder(
                        builder: (context) {
                          final section = sectionProvider.getSection(
                            widget.versionID,
                            sectionCode,
                          )!;
                          return GestureDetector(
                            onTap: () {
                              localVersionProvider.addSectionToStruct(
                                widget.versionID ?? -1,
                                sectionCode,
                              );
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorScheme.surfaceContainerHigh,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: section.contentColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      section.contentCode,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.shadow,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),

                FilledTextButton(
                  text: AppLocalizations.of(context)!.cancel,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _togglePalette() {
    setState(() {
      paletteIsOpen = !paletteIsOpen;
    });
  }
}
