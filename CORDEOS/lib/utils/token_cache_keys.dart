// ═══════════════════════════════════════════════════════════════════════════
// CACHE KEY FOR LAYOUT-DEPENDENT DATA
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Composite key for position cache that includes all layout dependencies.
/// Two keys are equal only if all parameters match.
class TokenCacheKey {
  String? content;
  final int sectionIndex;
  double? maxWidth;
  double? lineSpacing;
  double? lineBreakSpacing;
  double? chordLyricSpacing;
  double? minChordSpacing;
  double? letterSpacing;
  bool? showChords;
  bool? showLyrics;
  bool isEditMode;
  int? transposeValue;
  Color? chordColor;
  Color? lyricColor;

  TokenCacheKey({
    this.content,
    this.maxWidth,
    this.lineSpacing,
    this.lineBreakSpacing,
    this.chordLyricSpacing,
    this.minChordSpacing,
    this.letterSpacing,
    this.showChords,
    this.showLyrics,
    this.transposeValue,
    required this.sectionIndex,
    this.isEditMode = false,
    this.chordColor,
    this.lyricColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenCacheKey &&
        other.content == content &&
        other.maxWidth == maxWidth &&
        other.lineSpacing == lineSpacing &&
        other.lineBreakSpacing == lineBreakSpacing &&
        other.chordLyricSpacing == chordLyricSpacing &&
        other.minChordSpacing == minChordSpacing &&
        other.letterSpacing == letterSpacing &&
        other.showChords == showChords &&
        other.showLyrics == showLyrics &&
        other.isEditMode == isEditMode &&
        other.transposeValue == transposeValue &&
        other.sectionIndex == sectionIndex;
  }

  @override
  int get hashCode => Object.hash(
    content,
    maxWidth,
    lineSpacing,
    lineBreakSpacing,
    chordLyricSpacing,
    minChordSpacing,
    letterSpacing,
    showChords,
    showLyrics,
    transposeValue,
    sectionIndex,
    isEditMode,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CACHE KEY HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Token cache key: content + filters + transposition
String tokenCacheKey(TokenCacheKey k) =>
    '${k.sectionIndex}|content:${k.content}|chords:${k.showChords}|lyrics:${k.showLyrics}|transposeValue:${k.transposeValue}|editMode:${k.isEditMode}';

String measurementKey(
  String text,
  TextStyle style, {
  bool isChordToken = false,
}) =>
    '$text|${style.fontFamily}|${style.fontSize}|${style.fontWeight?.value}${isChordToken ? '|chordToken' : ''}';

String separatorKey(TextStyle chordStyle, TextStyle lyricStyle) =>
    'SEP|${lyricStyle.fontFamily}|${chordStyle.fontFamily}|${lyricStyle.fontSize}|${chordStyle.fontSize}';

String chordTargetKey(
  String text,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) =>
    'CT|$text|${chordStyle.fontFamily}|${chordStyle.fontSize}|${lyricStyle.fontSize}';

/// Position cache key: token key + layout params + Style params
String positionCacheKey(
  TokenCacheKey k,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) {
  return '${ //
  tokenCacheKey(k)}|w:${ //
  k.maxWidth}|ls:${ //
  k.lineSpacing}|lbs:${ //
  k.lineBreakSpacing}|cls:${ //
  k.chordLyricSpacing}|mcs:${ //
  k.minChordSpacing}|lts:${ //
  k.letterSpacing}|lStyle:${ //
  lyricStyle.fontFamily}|lSize:${ //
  lyricStyle.fontSize}|cStyle:${ //
  chordStyle.fontFamily}|cSize:${ //
  chordStyle.fontSize}';
}

String paintCacheKey(
  TokenCacheKey k,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) =>
    '${positionCacheKey(k, chordStyle, lyricStyle)}|chordColor:${ //
    k.chordColor}|lyricColor:${ //
    k.lyricColor}';
