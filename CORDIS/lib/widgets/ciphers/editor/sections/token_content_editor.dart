import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:flutter/material.dart';
import 'package:cordis/models/ui/content_token.dart';
import 'package:cordis/services/tokenization_service.dart';
import 'package:provider/provider.dart';

class TokenContentEditor extends StatefulWidget {
  final dynamic versionId;
  final String sectionCode;
  final bool isEnabled;

  const TokenContentEditor({
    super.key,
    required this.versionId,
    required this.sectionCode,
    this.isEnabled = true,
  });

  @override
  State<TokenContentEditor> createState() => _TokenContentEditorState();
}

class _TokenContentEditorState extends State<TokenContentEditor> {
  final TokenizationService _tokenizer = TokenizationService();

  bool _isDragging = false;

  bool _isEnabled(SelectionProvider selectionProvider) {
    if (!widget.isEnabled) return false;
    return !selectionProvider.isSelectionMode;
  }

  void _toggleDrag() {
    setState(() {
      _isDragging = !_isDragging;
    });
  }

  void _cacheChanges(List<ContentToken> tokens) {
    final newContent = _tokenizer.reconstructContent(
      tokens, // Excludes the last newline token
    );

    context.read<SectionProvider>().cacheUpdate(
      widget.versionId,
      widget.sectionCode,
      newContentText: newContent,
    );
  }

  void _addChord(List<ContentToken> tokens, ContentToken token, int position) {
    tokens.insert(position, token);

    _cacheChanges(tokens);
  }

  void _addPrecedingChord(
    List<ContentToken> tokens,
    ContentToken token,
    int position,
  ) {
    final emptySpaceToken = ContentToken(text: ' ', type: TokenType.space);
    final newToken = ContentToken(text: token.text, type: token.type);

    tokens.insert(position, emptySpaceToken);
    tokens.insert(position, newToken);

    _cacheChanges(tokens);
  }

  void _removeChordAt(List<ContentToken> tokens, int position) {
    tokens.removeAt(position);

    _cacheChanges(tokens);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer3<
      LayoutSettingsProvider,
      SectionProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            layoutSettingsProvider,
            sectionProvider,
            selectionProvider,
            child,
          ) {
            final section = sectionProvider.getSection(
              widget.versionId,
              widget.sectionCode,
            );

            // Handle case where section doesn't exist
            if (section == null || section.contentText.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.shadow,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Section not found or empty',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }

            final tokens = _tokenizer.tokenize(section.contentText);
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
                  Row(
                    spacing: 8,
                    children: [
                      /// Drag Handle icon
                      Icon(
                        Icons.drag_indicator,
                        size: 32,
                        color: colorScheme.shadow,
                      ),

                      /// Section Code badge
                      Container(
                        height: 30,
                        width: 40,
                        decoration: BoxDecoration(
                          color: section.contentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            section.contentCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      /// Section Type label
                      Expanded(
                        child: Text(
                          section.contentType,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      /// Delete icon (only visible when dragging)
                      _isDragging
                          ? DragTarget<ContentToken>(
                              onAcceptWithDetails: (details) => {
                                _removeChordAt(tokens, details.data.position!),
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
                      _isEnabled(selectionProvider)
                          ? IconButton(
                              onPressed: () {
                                context
                                    .read<NavigationProvider>()
                                    .pushForeground(
                                      EditSectionScreen(
                                        sectionCode: widget.sectionCode,
                                        versionId: widget.versionId,
                                      ),
                                    );
                              },
                              icon: const Icon(Icons.edit),
                            )
                          : SizedBox(height: 48),
                    ],
                  ),

                  Divider(height: 1.2, color: colorScheme.shadow),

                  /// CONTENT
                  Builder(
                    builder: (context) {
                      final widgetsWithSize = _tokenizer.buildTokenWidgets(
                        tokens,
                        layoutSettingsProvider.fontFamily,
                        section.contentColor,
                        _toggleDrag,
                        _addChord,
                        _addPrecedingChord,
                        _removeChordAt,
                        _isEnabled(selectionProvider),
                      );

                      final content = _tokenizer.positionWidgets(
                        context,
                        widgetsWithSize,
                        lineSpacing: 15,
                        letterSpacing: 0,
                      );

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: content.contentHeight,
                          child: Stack(children: [...content.tokens]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
    );
  }
}
