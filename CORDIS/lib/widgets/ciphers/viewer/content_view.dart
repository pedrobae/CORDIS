import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/utils/section_helper.dart';
import 'section_card.dart';

class ContentView extends StatefulWidget {
  final dynamic versionId;

  const ContentView({super.key, required this.versionId});
  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final List<GlobalKey> sectionKeys = [];
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer4<
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      LayoutSettingsProvider
    >(
      builder:
          (
            context,
            versionProvider,
            cloudVersionProvider,
            sectionProvider,
            layoutSettings,
            child,
          ) {
            final List<String> songStructure;

            if (widget.versionId is String) {
              songStructure = cloudVersionProvider
                  .getVersion(widget.versionId)!
                  .songStructure;
            } else {
              songStructure = versionProvider
                  .getVersion(widget.versionId)!
                  .songStructure;
            }

            final filteredStructure = songStructure
                .where(
                  (sectionCode) =>
                      ((layoutSettings.showAnnotations ||
                          !isAnnotation(sectionCode)) &&
                      (layoutSettings.showTransitions ||
                          !isTransition(sectionCode))),
                )
                .toList()
                .asMap();

            final sectionCardList = filteredStructure.entries.map((entry) {
              String trimmedCode = entry.value.trim();

              final section = sectionProvider.getSection(
                widget.versionId,
                trimmedCode,
              );

              if (section == null) {
                return const Center(child: CircularProgressIndicator());
              }

              sectionKeys.add(GlobalKey());

              if (section.contentText.isEmpty) {
                return const SizedBox.shrink();
              }

              return SectionCard(
                key: sectionKeys[entry.key],
                sectionType: section.contentType,
                sectionCode: trimmedCode,
                sectionText: section.contentText,
                sectionColor: section.contentColor,
              );
            }).toList();

            // Add space at the end of the list for better scrolling
            sectionCardList.add(SizedBox(height: 200));

            return Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                      child: Text(
                        AppLocalizations.of(context)!.songStructure,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    StructureList(
                      versionId: widget.versionId,
                      filteredStructure: filteredStructure.values.toList(),
                      scrollController: scrollController,
                      sectionKeys: sectionKeys,
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                          width: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        spacing: 16,
                        children: [
                          SizedBox(),
                          // Your structure list...
                          MasonryGridView.count(
                            crossAxisCount: layoutSettings.columnCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            itemCount: sectionCardList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) =>
                                sectionCardList[index],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }
}
