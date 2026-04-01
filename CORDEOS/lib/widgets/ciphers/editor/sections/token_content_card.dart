import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:provider/provider.dart';

class TokenContentCard extends StatefulWidget {
  final int versionID;
  final String sectionCode;
  final bool isEnabled;

  const TokenContentCard({
    super.key,
    required this.versionID,
    required this.sectionCode,
    this.isEnabled = true,
  });

  @override
  State<TokenContentCard> createState() => _TokenContentCardState();
}

class _TokenContentCardState extends State<TokenContentCard> {
  static const TokenizationService _tokenizer = TokenizationService();

  bool _isDragging = false;

  List<ContentToken>? _activeTokens;
  String? _activeContent;

  void _toggleDrag() {
    setState(() {
      _isDragging = !_isDragging;
    });
  }

  List<ContentToken> _tokensForContent(
    String content, {
    required bool triggerBuild,
  }) {
    final shouldRetokenize =
        _activeTokens == null || (!_isDragging && _activeContent != content);

    if (shouldRetokenize) {
      if (triggerBuild) {
        setState(() {
          _activeTokens = _tokenizer.tokenize(content);
          _activeContent = content;
        });
      } else {
        _activeTokens = _tokenizer.tokenize(content);
        _activeContent = content;
      }
    }

    return _activeTokens!;
  }

  void _cacheChanges() {
    if (_activeTokens == null) return;

    final newContent = _tokenizer.reconstructContent(_activeTokens!);

    context.read<SectionProvider>().cacheContent(
      versionID: widget.versionID,
      sectionCode: widget.sectionCode,
      content: newContent,
    );

    _tokensForContent(newContent, triggerBuild: true);
  }

  void _addChord(ContentToken draggable, ContentToken target) {
    if (_activeTokens == null) return;

    int index = 0;
    for (var token in _activeTokens!) {
      if (token == target) break;
      index++;
    }
    if (target.type == TokenType.postSeparator) {
      index++;
    }
    _activeTokens!.insert(index, draggable);

    _cacheChanges();
  }

  void _removeChord(ContentToken draggable) {
    if (_activeTokens == null) return;

    final index = _activeTokens!.indexOf(draggable);
    if (index >= 0 && index < _activeTokens!.length) {
      _activeTokens!.removeAt(index);
    }

    _cacheChanges();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Selector3<
      SectionProvider,
      TranspositionProvider,
      LayoutSetProvider,
      ({
        Section? section,
        Function(String) transpose,
        double lineSpacing,
        double lineBreakSpacing,
        double chordLyricSpacing,
        double minChordSpacing,
        double letterSpacing,
        TextStyle chordStyle,
        TextStyle lyricStyle,
      })
    >(
      selector: (context, sect, trans, laySet) {
        return (
          section: sect.getSection(widget.versionID, widget.sectionCode),
          transpose: trans.transposeChord,
          lineSpacing: laySet.lineSpacing,
          lineBreakSpacing: laySet.lineBreakSpacing,
          chordLyricSpacing: laySet.chordLyricSpacing,
          minChordSpacing: laySet.minChordSpacing,
          letterSpacing: laySet.letterSpacing,
          chordStyle: laySet.chordTextStyle(colorScheme.surface),
          lyricStyle: laySet.lyricTextStyle,
        );
      },
      builder: (context, s, child) {
        if (s.section == null) {
          return const Center(child: CircularProgressIndicator());
        }

        _tokensForContent(s.section!.contentText, triggerBuild: false);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: colorScheme.shadow, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border(
                    bottom: BorderSide(color: colorScheme.shadow, width: 1.2),
                  ),
                ),
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /// Section Code badge
                    SectionBadge(
                      sectionCode: s.section!.contentCode,
                      sectionColor: s.section!.contentColor,
                    ),

                    /// Section Type label
                    Expanded(
                      child: Text(
                        s.section!.contentType,
                        style: textTheme.bodyLarge,
                      ),
                    ),

                    /// Delete icon (only visible when dragging)
                    _isDragging
                        ? DragTarget<ContentToken>(
                            onAcceptWithDetails: (details) => {
                              _removeChord(details.data),
                            },
                            builder: (context, candidateData, rejectedData) {
                              if (candidateData.isNotEmpty) {
                                return Icon(Icons.delete, color: Colors.red);
                              }
                              return Icon(Icons.delete, color: Colors.grey);
                            },
                          )
                        : const SizedBox.shrink(),

                    /// Edit Section button
                    if (widget.isEnabled)
                      GestureDetector(
                        onTap: _showQuickActions,
                        child: Icon(
                          Icons.more_vert,
                          size: 28,
                          color: colorScheme.shadow,
                        ),
                      ),
                  ],
                ),
              ),

              /// CONTENT
              Padding(
                padding: const EdgeInsets.all(4),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: TokenizationConstants.chordTokenWidthPadding,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final buildCtx = TokenBuildContext(
                        chordStyle: s.chordStyle,
                        lyricStyle: s.lyricStyle,
                        contentColor: s.section!.contentColor,
                        surfaceColor: colorScheme.surface,
                        onSurfaceColor: colorScheme.onSurface,
                        chordTargetColor: colorScheme.surfaceTint,
                        isEnabled: widget.isEnabled,
                        cache: {},
                        maxWidth: constraints.maxWidth,
                        transposeChord: (String chord) => s.transpose(chord),
                        toggleDrag: _toggleDrag,
                        onAddChord: _addChord,
                        onRemoveChord: _removeChord,
                      );

                      final content = _tokenizer.createContent(
                        content: s.section!.contentText,
                        initialTokens: _activeTokens,
                        posCtx: PositioningContext(
                          underLineColor: colorScheme.onSurface,
                          maxWidth: constraints.maxWidth,
                          isEditMode: true,
                          lineSpacing: s.lineSpacing,
                          lineBreakSpacing: s.lineBreakSpacing,
                          chordLyricSpacing: s.chordLyricSpacing,
                          minChordSpacing: s.minChordSpacing,
                          letterSpacing: s.letterSpacing,
                        ),
                        buildCtx: buildCtx,
                        showChords: true,
                        showLyrics: true,
                      );

                      return SizedBox(
                        width: double.infinity,
                        height: content.contentHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [...content.tokens],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quickAction,
                    style: textTheme.titleMedium,
                  ),
                  CloseButton(onPressed: () => Navigator.pop(context)),
                ],
              ),

              // ACTIONS
              // edit
              FilledTextButton(
                text: AppLocalizations.of(context)!.editPlaceholder(''),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  context.read<NavigationProvider>().pushForeground(
                    EditSectionScreen(
                      versionID: widget.versionID,
                      sectionCode: widget.sectionCode,
                    ),
                  );
                },
              ),
              // merge
              FilledTextButton(
                text: AppLocalizations.of(context)!.mergePlaceholder(''),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  final state = context.read<EditSectionsStateProvider>();
                  state.enableMergeOverlay();
                  state.toggleMergeSection(widget.sectionCode);
                },
              ),
              // create copy
              FilledTextButton(
                text: AppLocalizations.of(
                  context,
                )!.createPlaceholder(AppLocalizations.of(context)!.copy),
                trailingIcon: Icons.chevron_right,
                tooltip: AppLocalizations.of(context)!.copySectionTooltip,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  final sect = context.read<SectionProvider>();
                  final newCode = sect.cacheCopyOfSection(
                    versionId: widget.versionID,
                    sectionCode: widget.sectionCode,
                  );
                  if (newCode != null) {
                    context.read<LocalVersionProvider>().addSectionToStruct(
                      widget.versionID,
                      newCode,
                    );
                  }
                },
              ),
              // duplicate (just to map)
              FilledTextButton(
                text: AppLocalizations.of(
                  context,
                )!.duplicatePlaceholder(AppLocalizations.of(context)!.section),
                trailingIcon: Icons.chevron_right,
                tooltip: AppLocalizations.of(context)!.duplicateSectionTooltip,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  context.read<LocalVersionProvider>().addSectionToStruct(
                    widget.versionID,
                    widget.sectionCode,
                  );
                },
              ),
              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                isDangerous: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.section,
                        onConfirm: () {
                          context.read<SectionProvider>().cacheDeletion(
                            widget.versionID,
                            widget.sectionCode,
                          );
                          context
                              .read<LocalVersionProvider>()
                              .removeSectionsByCode(
                                widget.versionID,
                                widget.sectionCode,
                              );
                          Navigator.pop(context); // Close quick actions sheet
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
