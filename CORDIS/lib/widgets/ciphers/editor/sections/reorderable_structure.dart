import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/widgets/common/custom_reorderable_delayed.dart';
import 'package:provider/provider.dart';

class ReorderableStructure extends StatefulWidget {
  final dynamic versionId;

  const ReorderableStructure({super.key, required this.versionId});

  @override
  State<ReorderableStructure> createState() => _ReorderableStructureState();
}

class _ReorderableStructureState extends State<ReorderableStructure> {
  void _reorder(
    int oldIndex,
    int newIndex,
    LocalVersionProvider localVersionProvider,
  ) {
    localVersionProvider.reorderSongStructure(
      widget.versionId ?? -1,
      oldIndex,
      newIndex,
    );
  }

  void _removeSection(
    int index,
    LocalVersionProvider localVersionProvider,
    SectionProvider sectionProvider,
  ) {
    final songStructure = localVersionProvider
        .cachedVersion(widget.versionId ?? -1)!
        .songStructure;

    final sectionCode = songStructure[index];

    songStructure.removeAt(index);

    if (!songStructure.contains(sectionCode)) {
      sectionProvider.cacheDeleteSection(widget.versionId ?? -1, sectionCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer3<
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider
    >(
      builder:
          (
            context,
            localVersionProvider,
            cloudVersionProvider,
            sectionProvider,
            child,
          ) {
            final List<String> songStructure;

            if (widget.versionId is int) {
              songStructure = localVersionProvider
                  .cachedVersion(widget.versionId ?? -1)!
                  .songStructure;
            } else {
              songStructure = cloudVersionProvider
                  .getVersion(widget.versionId ?? -1)!
                  .songStructure;
            }

            return Container(
              padding: EdgeInsets.all(8),
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surfaceContainerLowest),
                borderRadius: BorderRadius.circular(0),
              ),
              child: songStructure.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.emptyStructure,
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ReorderableListView.builder(
                      proxyDecorator: (child, index, animation) => Material(
                        type: MaterialType.transparency,
                        child: child,
                      ),
                      buildDefaultDragHandles: false,
                      scrollDirection: Axis.horizontal,
                      itemCount: songStructure.length,

                      onReorder: (oldIndex, newIndex) =>
                          _reorder(oldIndex, newIndex, localVersionProvider),
                      itemBuilder: (context, index) {
                        final sectionCode = songStructure[index];
                        final section = sectionProvider.getSection(
                          widget.versionId,
                          sectionCode,
                        )!;
                        final color = section.contentColor;

                        return CustomReorderableDelayed(
                          delay: Duration(milliseconds: 100),
                          key: ValueKey('$sectionCode-$index'),
                          index: index,

                          child: Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 4),
                                height: 44,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .90),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: Text(
                                    sectionCode,
                                    style: TextStyle(
                                      color: colorScheme.surface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -3,
                                right: 1, // Right margin is 4
                                child: GestureDetector(
                                  onTap: () => _removeSection(
                                    index,
                                    localVersionProvider,
                                    sectionProvider,
                                  ),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: colorScheme.surface,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
    );
  }
}
