import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/select_type.dart';
import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditSectionScreen extends StatefulWidget {
  final int? versionID;
  final String? sectionCode;
  final bool isNewSection;

  const EditSectionScreen({
    super.key,
    required this.sectionCode,
    required this.versionID,
    this.isNewSection = false,
  });

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late TextEditingController contentCodeController;
  late TextEditingController contentTypeController;
  late TextEditingController contentTextController;
  late Color contentColor;

  @override
  void initState() {
    super.initState();

    Section? section = context.read<SectionProvider>().getSection(
      widget.versionID,
      widget.sectionCode ?? '',
    );

    contentCodeController = TextEditingController(
      text: section?.contentCode ?? '',
    );
    contentTypeController = TextEditingController(
      text: section?.contentType ?? '',
    );
    contentTextController = TextEditingController(
      text: section?.contentText ?? '',
    );
    contentColor = section?.contentColor ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Column(
        spacing: 16,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BackButton(
                color: colorScheme.onSurface,
                onPressed: () => context.read<NavigationProvider>().pop(),
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!.editPlaceholder(AppLocalizations.of(context)!.section),
                style: textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () {
                  _upsertSection();
                  context.read<NavigationProvider>().pop();
                },
                icon: Icon(Icons.save, size: 24, color: colorScheme.onSurface),
              ),
            ],
          ),

          // CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TYPE SELECTION
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: contentColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            contentTypeController.text,

                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _upsertSection();
                            context.read<NavigationProvider>().pushForeground(
                              SelectType(
                                versionID: widget.versionID,
                                sectionCode: widget.sectionCode,
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.changePlaceholder(
                              AppLocalizations.of(context)!.type,
                            ),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8),
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
                          contentPadding: EdgeInsets.all(8),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.surfaceContainerLow,
                            ),
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // SECTION TEXT
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
                          contentPadding: EdgeInsets.all(8),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.surfaceContainerLow,
                            ),
                            borderRadius: BorderRadius.circular(0),
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

                  // DELETE BUTTON
                  if (!widget.isNewSection)
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
                                context.read<NavigationProvider>().pop();
                              },
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _upsertSection() {
    // New section was added when selecting type, so just update it
    // Update the section with new values
    context.read<SectionProvider>().cacheUpdate(
      widget.versionID,
      widget.sectionCode!,
      newContentCode: contentCodeController.text,
      newContentType: contentTypeController.text,
      newContentText: contentTextController.text,
      newColor: contentColor,
    );

    // If it is a new section Add the section to the song structure
    if (widget.isNewSection) {
      context.read<LocalVersionProvider>().addSectionToStruct(
        widget.versionID!,
        widget.sectionCode ?? contentCodeController.text,
      );
    }

    // If the content code has changed, update the song structure accordingly
    if (contentCodeController.text.isNotEmpty &&
        contentCodeController.text != widget.sectionCode) {
      context.read<LocalVersionProvider>().updateSectionCodeInStruct(
        widget.versionID!,
        oldCode: widget.sectionCode!,
        newCode: contentCodeController.text,
      );

      context.read<SectionProvider>().renameSectionKey(
        widget.versionID!,
        oldCode: widget.sectionCode!,
        newCode: contentCodeController.text,
      );
    }
  }

  void _deleteSection() {
    if (widget.isNewSection) return;

    context.read<SectionProvider>().cacheDeleteSection(
      widget.versionID!,
      widget.sectionCode!,
    );
    context.read<LocalVersionProvider>().removeSectionFromStructByCode(
      widget.versionID!,
      widget.sectionCode!,
    );
  }
}
