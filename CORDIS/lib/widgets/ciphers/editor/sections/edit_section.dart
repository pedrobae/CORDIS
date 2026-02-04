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
      builder: (context, navigationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              color: colorScheme.onSurface,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(
                context,
              )!.editPlaceholder(AppLocalizations.of(context)!.section),
              style: textTheme.titleMedium,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _upsertSection();
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.save, size: 24, color: colorScheme.onSurface),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.surfaceContainerLowest,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: navigationProvider.currentRoute.index,
              selectedLabelStyle: TextStyle(
                color: colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 2,
              onTap: (index) {
                if (mounted) {
                  navigationProvider.navigateToRoute(
                    NavigationRoute.values[index],
                  );
                  Navigator.of(context).pop();
                }
              },
              items: navigationProvider
                  .getNavigationItems(
                    context,
                    iconSize: 28,
                    color: colorScheme.onSurface,
                    activeColor: colorScheme.primary,
                  )
                  .map(
                    (navItem) => BottomNavigationBarItem(
                      icon: navItem.icon,
                      label: navItem.title,
                      backgroundColor: colorScheme.surface,
                      activeIcon: navItem.activeIcon,
                    ),
                  )
                  .toList(),
            ),
          ),
          body: Container(
            padding: EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 24),
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

                  // SECTION COLOR
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
                          contentPadding: EdgeInsets.all(8),
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
                                      shape: BoxShape.circle,
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
                                      shape: BoxShape.circle,
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
                                Navigator.of(context).pop();
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
        );
      },
    );
  }

  void _upsertSection() {
    // Update the section with new values
    context.read<SectionProvider>().cacheSection(
      widget.versionId,
      widget.sectionCode,
      newContentCode: contentCodeController.text,
      newContentType: contentTypeController.text,
      newContentText: contentTextController.text,
      newColor: contentColor,
    );
    // If the content code has changed, update the song structure accordingly
    if (contentCodeController.text.isNotEmpty &&
        contentCodeController.text != widget.sectionCode) {
      context.read<LocalVersionProvider>().updateSectionCodeInStruct(
        widget.versionId,
        oldCode: widget.sectionCode,
        newCode: contentCodeController.text,
      );

      context.read<SectionProvider>().renameSectionKey(
        widget.versionId,
        oldCode: widget.sectionCode,
        newCode: contentCodeController.text,
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
