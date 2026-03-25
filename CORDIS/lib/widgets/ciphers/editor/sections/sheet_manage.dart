import "package:cordis/l10n/app_localizations.dart";
import "package:cordis/providers/section_provider.dart";
import "package:cordis/providers/version/local_version_provider.dart";
import "package:cordis/widgets/ciphers/editor/sections/reorderable_structure.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class RepeatSectionSheet extends StatefulWidget {
  final int versionID;
  const RepeatSectionSheet({super.key, required this.versionID});

  @override
  State<RepeatSectionSheet> createState() => _RepeatSectionSheetState();
}

class _RepeatSectionSheetState extends State<RepeatSectionSheet> {
    void Function()? _scrollToEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final localVer = context.read<LocalVersionProvider>();

    return Selector<LocalVersionProvider, List<String>>(
      selector: (context, localVer) {
        return localVer.getSongStructure(widget.versionID);
      },
      builder: (context, songStructure, child) {
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
          child: Column(
            spacing: 16,
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
                        AppLocalizations.of(context)!.managePlaceholder(
                          AppLocalizations.of(context)!.section,
                        ),
                        style: textTheme.titleMedium,
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
              ReorderableStructure(versionID: widget.versionID, onInit: (scrollToEnd) {
                _scrollToEnd = scrollToEnd;
              },),
              Expanded(
                child: ListView(
                  children: [
                    for (var sectionCode in songStructure.toSet())
                      Builder(
                        builder: (context) {
                          final sect = context.read<SectionProvider>();
                          final section = sect.getSection(
                            widget.versionID,
                            sectionCode,
                          )!;
                          return GestureDetector(
                            onTap: () {
                              localVer.addSectionToStruct(
                                widget.versionID,
                                sectionCode,
                              );
                              if (_scrollToEnd != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollToEnd!();
                                });
                              }
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
                                      style: textTheme.bodyLarge,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
