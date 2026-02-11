import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class PlayLocalVersion extends StatefulWidget {
  final int versionId;

  const PlayLocalVersion({super.key, required this.versionId});

  @override
  State<PlayLocalVersion> createState() => _PlayLocalVersionState();
}

class _PlayLocalVersionState extends State<PlayLocalVersion> {
  late final ScrollController _scrollController;
  late final List<GlobalKey> sectionKeys = [];
  final _headerSectionKey = GlobalKey();
  bool showTopBar = false;
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDataLoaded();
      _initializeSectionKeys();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateHeaderHeight();
          _scrollController.addListener(_scrollListener);
        }
      });
    });
  }

  Future<void> _ensureDataLoaded() async {
    final versionProvider = context.read<LocalVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    await versionProvider.loadVersion(widget.versionId);
    await sectionProvider.loadLocalSections(widget.versionId);
  }

  void _initializeSectionKeys() {
    final versionProvider = context.read<LocalVersionProvider>();
    final layoutProvider = context.read<LayoutSettingsProvider>();

    final version = versionProvider.cachedVersion(widget.versionId);

    if (version == null) return;

    final filteredStructure = version.songStructure
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Use pre-calculated header height as threshold for showing sticky bar
    final offset = _scrollController.offset;
    final shouldShow = offset > _headerHeight;

    if (shouldShow != showTopBar) {
      setState(() {
        showTopBar = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer4<
      CipherProvider,
      LocalVersionProvider,
      SectionProvider,
      LayoutSettingsProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            sectionProvider,
            layoutProvider,
            child,
          ) {
            if (sectionKeys.isEmpty) {
              _initializeSectionKeys();
            }

            final version = versionProvider.cachedVersion(widget.versionId);

            // LOADING STATE
            if (versionProvider.isLoading ||
                sectionProvider.isLoading ||
                version == null) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }
            final cipher = cipherProvider.getCipherById(version.cipherId);

            if (cipher == null) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final filteredStructure = version.songStructure
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
                              _buildHeader(cipher, version, textTheme),
                              // SONG STRUCTURE
                              Column(
                                spacing: 4,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.songStructure,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    key: _headerSectionKey,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: colorScheme
                                              .surfaceContainerLowest,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: StructureList(
                                      versionId: widget.versionId,
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
                          _buildSectionGrid(
                            sectionProvider,
                            layoutProvider,
                            filteredStructure,
                          ),
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

  Widget _buildHeader(Cipher cipher, Version version, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          cipher.title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        _buildMetadataRow(version, textTheme),
      ],
    );
  }

  Widget _buildMetadataRow(Version version, TextTheme textTheme) {
    final bodyStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );
    return Row(
      spacing: 16.0,
      children: [
        Text(
          AppLocalizations.of(context)!.keyWithPlaceholder(
            version.transposedKey ?? version.cipherId.toString(),
          ),
          style: bodyStyle,
        ),
        Text(
          AppLocalizations.of(context)!.bpmWithPlaceholder(version.bpm),
          style: bodyStyle,
        ),
        Text(
          '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(version.duration)}',
          style: bodyStyle,
        ),
      ],
    );
  }

  Widget _buildSectionGrid(
    SectionProvider sectionProvider,
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
        final section = sectionProvider.getSection(
          widget.versionId,
          trimmedCode,
        );

        if (section == null) {
          return const SizedBox.shrink();
        }

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
          padding: const EdgeInsets.symmetric(vertical: 10.0),
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
            ),
            child: StructureList(
              versionId: widget.versionId,
              filteredStructure: filteredStructure,
              scrollController: _scrollController,
              sectionKeys: sectionKeys,
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
