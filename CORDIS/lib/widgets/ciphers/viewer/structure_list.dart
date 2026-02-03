import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StructureList extends StatefulWidget {
  final dynamic versionId;
  final List<String> filteredStructure;
  final ScrollController scrollController;
  final List<GlobalKey> sectionKeys;

  const StructureList({
    super.key,
    required this.versionId,
    required this.filteredStructure,
    required this.scrollController,
    required this.sectionKeys,
  });

  @override
  State<StructureList> createState() => _StructureListState();
}

class _StructureListState extends State<StructureList> {
  final listScrollController = ScrollController();

  void _scrollToSection(BuildContext context, int index) {
    if (index >= widget.sectionKeys.length) return;

    final sectionKey = widget.sectionKeys[index];
    final renderBox =
        sectionKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero).dy;

    widget.scrollController.animateTo(
      widget.scrollController.offset + offset - 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    listScrollController.animateTo(
      (index * 52 - 150).toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    listScrollController.dispose();
    super.dispose();
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
            return Container(
              padding: EdgeInsets.all(8),
              height: 64,
              child: widget.filteredStructure.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.emptyStructure,
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: listScrollController,
                      child: Row(
                        spacing: 8,
                        children: [
                          ...widget.filteredStructure.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final sectionCode = entry.value;
                            final section = (widget.versionId is int)
                                ? sectionProvider.getSection(
                                    widget.versionId,
                                    sectionCode,
                                  )
                                : (cloudVersionProvider.getVersion(
                                            widget.versionId,
                                          ) !=
                                          null
                                      ? Section.fromFirestore(
                                          cloudVersionProvider
                                              .getVersion(widget.versionId)!
                                              .sections[sectionCode]!,
                                        )
                                      : null);

                            // Loading state
                            if (section == null || sectionProvider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            final color = section.contentColor;
                            return RepaintBoundary(
                              child: GestureDetector(
                                onTap: () => _scrollToSection(context, index),
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .8),
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(
                                      color: colorScheme.shadow,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      sectionCode,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            );
          },
    );
  }
}
