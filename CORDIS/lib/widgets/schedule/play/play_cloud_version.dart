import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/utils/section_helper.dart';
import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class PlayCloudVersion extends StatefulWidget {
  final VersionDto versionDTO;

  const PlayCloudVersion({super.key, required this.versionDTO});

  @override
  State<PlayCloudVersion> createState() => _PlayCloudVersionState();
}

class _PlayCloudVersionState extends State<PlayCloudVersion> {
  late final ScrollController _scrollController;
  late final List<GlobalKey> sectionKeys = [];
  final _headerSectionKey = GlobalKey();
  bool showTopBar = false;
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _initializeSectionKeys();

    // Give the tree one full frame cycle to rebuild and layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateHeaderHeight();
        _scrollController.addListener(_scrollListener);
      }
    });
  }

  void _initializeSectionKeys() {
    final layoutProvider = Provider.of<LayoutSettingsProvider>(
      context,
      listen: false,
    );

    final filteredStructure = widget.versionDTO.songStructure
        .where(
          (sectionCode) =>
              ((layoutProvider.showAnnotations || !isAnnotation(sectionCode)) &&
              (layoutProvider.showTransitions || !isTransition(sectionCode))),
        )
        .toList();

    sectionKeys.clear();
    for (int i = 0; i < filteredStructure.length; i++) {
      sectionKeys.add(GlobalKey());
    }
  }

  void _calculateHeaderHeight() {
    final headerContext = _headerSectionKey.currentContext;
    if (headerContext != null) {
      final box = headerContext.findRenderObject() as RenderBox?;
      if (box != null) {
        _headerHeight = box.size.height + kToolbarHeight + 10;
      }
    }
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    final shouldShow = offset > _headerHeight;

    if (shouldShow != showTopBar) {
      setState(() {
        showTopBar = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<LayoutSettingsProvider>(
      builder: (context, layoutProvider, child) {
        if (sectionKeys.isEmpty) {
          _initializeSectionKeys();
        }

        final filteredStructure = widget.versionDTO.songStructure
            .where(
              (sectionCode) =>
                  ((layoutProvider.showAnnotations ||
                      !isAnnotation(sectionCode)) &&
                  (layoutProvider.showTransitions ||
                      !isTransition(sectionCode))),
            )
            .toList();

        return Stack(
          children: [
            // MAIN SCROLLABLE CONTENT - Wrapped in RepaintBoundary for isolation
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      const SizedBox(height: 8),
                      // Header section for height measurement
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          _buildHeader(),
                          // SONG STRUCTURE
                          Column(
                            spacing: 4,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.songStructure,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                key: _headerSectionKey,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  border: Border.fromBorderSide(
                                    BorderSide(
                                      color: colorScheme.surfaceContainerLowest,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: StructureList(
                                  versionId: widget.versionDTO.firebaseId,
                                  filteredStructure: filteredStructure,
                                  scrollController: _scrollController,
                                  sectionKeys: sectionKeys,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // SECTION CARDS GRID
                      _buildSectionGrid(layoutProvider, filteredStructure),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),

            // SCROLL-CONDITIONAL TOP SONG STRUCTURE BAR
            if (showTopBar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _buildStickyBar(
                    context,
                    colorScheme,
                    filteredStructure,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          widget.versionDTO.title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        _buildMetadataRow(textTheme),
      ],
    );
  }

  Widget _buildMetadataRow(TextTheme textTheme) {
    final bodyStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );
    return Row(
      spacing: 16.0,
      children: [
        Text(
          AppLocalizations.of(context)!.keyWithPlaceholder(
            widget.versionDTO.transposedKey ?? widget.versionDTO.originalKey,
          ),
          style: bodyStyle,
        ),
        Text(
          AppLocalizations.of(
            context,
          )!.bpmWithPlaceholder(widget.versionDTO.bpm),
          style: bodyStyle,
        ),
        Text(
          '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(Duration(seconds: widget.versionDTO.duration))}',
          style: bodyStyle,
        ),
      ],
    );
  }

  Widget _buildSectionGrid(
    LayoutSettingsProvider layoutProvider,
    List<String> filteredStructure,
  ) {
    return MasonryGridView.count(
      crossAxisCount: layoutProvider.columnCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: filteredStructure.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final trimmedCode = filteredStructure[index].trim();
        final sectionMap = widget.versionDTO.sections[trimmedCode];
        if (sectionMap == null) {
          return const SizedBox.shrink();
        }
        final section = Section.fromFirestore(sectionMap);

        return RepaintBoundary(
          child: SectionCard(
            key: sectionKeys[index],
            sectionType: section.contentType,
            sectionCode: trimmedCode,
            sectionText: section.contentText,
            sectionColor: section.contentColor,
          ),
        );
      },
    );
  }

  Widget _buildStickyBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<String> filteredStructure,
  ) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
              bottom: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 66,
              minWidth: MediaQuery.of(context).size.width - 66,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              child: StructureList(
                versionId: widget.versionDTO.firebaseId,
                filteredStructure: filteredStructure,
                scrollController: _scrollController,
                sectionKeys: sectionKeys,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
              bottom: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
              top: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
            ),
          ),
          height: 66,
          width: 66,
        ),
      ],
    );
  }
}
