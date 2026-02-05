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
import 'package:cordis/widgets/ciphers/editor/sections/token_content_editor.dart';
import 'package:cordis/utils/section_constants.dart';

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
                uniqueSections = localVersionProvider
                    .getVersion(widget.versionID ?? -1)!
                    .songStructure
                    .toSet()
                    .toList();
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
                                            .getVersion(widget.versionID)!
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
                          spacing: 8,
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
                                return TokenContentEditor(
                                  versionId: widget.versionID,
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

  void _addSection(
    SectionLabel sectionLabel,
    SectionProvider sectionProvider,
    LocalVersionProvider versionProvider,
  ) {
    final isNewSection = !sectionProvider
        .getSections(widget.versionID)
        .containsKey(sectionLabel.code);

    // Add section to song structure
    versionProvider.addSectionToStruct(widget.versionID, sectionLabel.code);
    // Add section to sections map if it's new
    if (isNewSection) {
      sectionProvider.cacheAddSection(
        widget.versionID,
        sectionLabel.code,
        sectionLabel.color,
        sectionLabel.officialLabel,
      );
    }

    Navigator.of(context).pop();
  }

  void _showRepeatSectionSheet(
    BuildContext context,
    SectionProvider sectionProvider,
    LocalVersionProvider versionProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    SectionLabel? selectedLabel;

    showModalBottomSheet(
      context: context,
      barrierColor: colorScheme.onSurface.withAlpha(85),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.duplicatePlaceholder(
                          AppLocalizations.of(context)!.section,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.duplicateSectionInstruction,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                ],
              ), // TODO CONTINUE HERE
              // LABEL
              Text(
                AppLocalizations.of(
                  context,
                )!.addPlaceholder(AppLocalizations.of(context)!.section),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),

              SizedBox(height: 8),

              // DROPDOWN MENU
              DropdownButtonFormField<SectionLabel>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.selectSectionType,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.surfaceContainerLowest,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                items: commonSectionLabels.values.map((sectionLabels) {
                  return DropdownMenuItem<SectionLabel>(
                    value: sectionLabels,
                    child: Text(
                      '${sectionLabels.code} - ${sectionLabels.officialLabel}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedLabel = value;
                },
              ),

              SizedBox(height: 16),

              FilledTextButton(
                text: AppLocalizations.of(context)!.save,
                onPressed: () {
                  _addSection(selectedLabel!, sectionProvider, versionProvider);
                },
                isDark: true,
              ),

              SizedBox(height: 40),
            ],
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
