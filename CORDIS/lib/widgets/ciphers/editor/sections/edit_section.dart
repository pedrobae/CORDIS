import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:provider/provider.dart';

class EditSectionScreen extends StatefulWidget {
  final dynamic versionId;
  final String sectionCode;

  const EditSectionScreen({
    super.key,
    required this.sectionCode,
    required this.versionId,
  });

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late TextEditingController contentCodeController;
  late TextEditingController contentTypeController;
  late TextEditingController contentTextController;
  late Color contentColor;
  late Section? section;
  Map<String, Color> availableColors = {};

  @override
  void initState() {
    section = context.read<SectionProvider>().getSection(
      widget.versionId,
      widget.sectionCode,
    );

    contentCodeController = TextEditingController(text: widget.sectionCode);

    contentTypeController = TextEditingController(
      text: section?.contentType ?? '',
    );

    contentTextController = TextEditingController(
      text: section?.contentText ?? '',
    );

    contentColor = section?.contentColor ?? Colors.grey;

    // Prepare available colors from common section labels
    List<Color> presetColors = [];
    for (var value in commonSectionLabels.values) {
      if (!presetColors.contains(value.color)) {
        availableColors[value.officialLabel] = value.color;
        presetColors.add(value.color);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom == 0
              ? 16
              : MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackButton(
                  color: colorScheme.onSurface,
                  onPressed: () => navigationProvider.pop(),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.editPlaceholder(AppLocalizations.of(context)!.section),
                  style: textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {
                    _upsertSection(
                      contentCodeController.text,
                      contentTypeController.text,
                      contentTextController.text,
                      contentColor,
                    );
                  },
                  icon: Icon(
                    Icons.save,
                    size: 24,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Column(
                  spacing: 16,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION CODE
                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.sectionCode,
                          style: textTheme.titleMedium,
                        ),

                        TextField(
                          controller: contentCodeController,
                          // enabled: widget.versionId == -1,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.sectionCodeHint,
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: colorScheme.surfaceContainerLow,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLow,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.sectionCodeInstruction,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.surfaceContainerLow,
                          ),
                        ),
                      ],
                    ),

                    // SECTION TYPE
                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.sectionType,
                          style: textTheme.titleMedium,
                        ),
                        TextField(
                          controller: contentTypeController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.sectionTypeHint,
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: colorScheme.surfaceContainerLow,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLow,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.sectionColor,
                          style: textTheme.titleMedium,
                        ),
                        // Default section colors picker
                        DropdownButtonFormField<Color>(
                          isDense: true,
                          iconSize: 32,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.sectionColorHint,
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: colorScheme.surfaceContainerLow,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLow,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          initialValue: contentColor,
                          items: [
                            if (!availableColors.values.contains(contentColor))
                              DropdownMenuItem<Color>(
                                value: contentColor,
                                child: Row(
                                  spacing: 12,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: contentColor,
                                        border: Border.all(color: contentColor),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    Text(AppLocalizations.of(context)!.current),
                                  ],
                                ),
                              ),
                            ...availableColors.entries.map(
                              (entry) => DropdownMenuItem<Color>(
                                value: entry.value,
                                child: Row(
                                  spacing: 12,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: entry.value,
                                        border: Border.all(color: entry.value),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    Text(entry.key),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (Color? newColor) {
                            setState(() {
                              contentColor = newColor!;
                            });
                          },
                        ),
                      ],
                    ),

                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.sectionText,
                          style: textTheme.titleMedium,
                        ),
                        TextField(
                          controller: contentTextController,
                          minLines: 6,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLow,
                              ),
                            ),
                            hintText: AppLocalizations.of(
                              context,
                            )!.sectionTextHint,
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.surfaceContainerLow,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.versionId != -1)
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                isDangerous: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.section,
                        onConfirm: () {
                          _deleteSection();
                          navigationProvider.pop();
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _upsertSection(String? code, String? type, String? text, Color? color) {
    // Update the section with new values
    context.read<SectionProvider>().cacheUpdatedSection(
      widget.versionId,
      widget.sectionCode,
      newContentCode: code,
      newContentType: type,
      newContentText: text,
      newColor: color,
    );
    // If the content code has changed, update the song structure accordingly
    if (code != null && code != widget.sectionCode) {
      context.read<LocalVersionProvider>().updateSectionCodeInStruct(
        widget.versionId,
        oldCode: widget.sectionCode,
        newCode: code,
      );

      context.read<SectionProvider>().renameSectionKey(
        widget.versionId,
        oldCode: widget.sectionCode,
        newCode: code,
      );
    }
  }

  void _deleteSection() {
    context.read<SectionProvider>().cacheDeleteSection(
      widget.versionId,
      widget.sectionCode,
    );
    context.read<LocalVersionProvider>().removeSectionFromStructByCode(
      widget.versionId,
      widget.sectionCode,
    );
  }
}
