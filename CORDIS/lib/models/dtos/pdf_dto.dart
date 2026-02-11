import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const double newLineThreshold = 2.0; // Tolerance for y-position differences
const double spaceThreshold = 1.0; // Threshold to detect spaces between words

class DocumentData {
  final String documentName;
  final Map<int, List<LineData>>
  pageLines; // Original without column reordering
  final Map<int, List<LineData>>
  pageLinesWithColumns; // With column reordering applied
  final Map<int, List<double>> projectedBounds; // bounds per page
  Map<int, bool> hasColumns; // Whether columns were detected per page

  DocumentData({
    required this.documentName,
    required this.pageLines,
    this.pageLinesWithColumns = const {},
    this.projectedBounds = const {},
    this.hasColumns = const {},
  });

  factory DocumentData.fromGlyphMap(
    Map<int, List<TextGlyph>> pageGlyphs,
    String docName,
  ) {
    Map<int, List<LineData>> pages = {};
    Map<int, List<double>> bounds = {};
    Map<int, List<LineData>> pagesWithColumns = {};
    Map<int, bool> columnDetection = {};
    for (var pageGlyph in pageGlyphs.entries) {
      int currentLineIndex = -1;
      double lastY = -1.0;
      Map<int, List<TextGlyph>> lineGlyphMap = {};
      for (var glyph in pageGlyph.value) {
        // Check if glyph starts a new line
        if ((lastY - glyph.bounds.top).abs() > newLineThreshold ||
            lastY == -1.0) {
          currentLineIndex++;
          lastY = glyph.bounds.top;
        }

        // Add glyph to the current line, on the correct position (x-axis)
        if (lineGlyphMap[currentLineIndex] == null) {
          lineGlyphMap[currentLineIndex] = [glyph];
        } else {
          final lineGlyph = lineGlyphMap[currentLineIndex]!;
          bool inserted = false;
          for (int i = 0; i < lineGlyph.length; i++) {
            if (glyph.bounds.left < lineGlyph[i].bounds.left) {
              inserted = true;
              lineGlyph.insert(i, glyph);
              break;
            }
          }
          if (!inserted) {
            lineGlyph.add(glyph);
          }
        }
      }

      List<LineData> lines = [];
      for (var entry in lineGlyphMap.entries) {
        if (entry.value.any((g) => g.text.trim().isNotEmpty)) {
          lines.add(LineData.fromGlyphArray(entry.key, entry.value));
        }
      }
      pages[pageGlyph.key] = lines;
    }

    return DocumentData(
      documentName: docName,
      pageLines: pages,
      projectedBounds: bounds,
      pageLinesWithColumns: pagesWithColumns,
      hasColumns: columnDetection,
    );
  }

  void searchColumns() {
    // See if the lines can be split into two columns

    // The x-coordinate of the left bound of the right column cannot be inside a word bound

    // 'project' the word bounds onto the x-axis and find gaps big enough to fit a column gap
    for (var pageEntry in pageLines.entries) {
      List<double> wordBounds = [];
      for (var line in pageEntry.value) {
        // Skip lines that have a too great left bound (to avoid titles)
        if (line.bounds!.left > 100.0) {
          continue;
        }
        for (var word in line.wordList!) {
          wordBounds = _projectWord(
            word.bounds.left,
            word.bounds.right,
            wordBounds,
          );
        }
      }

      // Save the projected bounds for visualization
      projectedBounds[pageEntry.key] = List<double>.from(wordBounds);

      if (wordBounds.length > 3) {
        // Find the biggest gap between projected bounds
        double maxGap = 0.0;
        double gapStart = 0.0;
        for (int i = 1; i < wordBounds.length - 1; i += 2) {
          double gap = wordBounds[i + 1] - wordBounds[i];
          if (gap > maxGap) {
            maxGap = gap;
            gapStart = wordBounds[i];
          }
        }

        // If the biggest gap is big enough, we have found a column split
        hasColumns[pageEntry.key] = true;

        // Create the column-reordered version
        List<LineData> rightColumnLines = [];
        List<LineData> leftColumnLines = [];
        bool startedContent = false;

        for (var line in pageEntry.value) {
          // Skip lines until we reach a left column line
          if (line.bounds!.left < 100.0) {
            startedContent = true;
          }

          if (!startedContent) {
            leftColumnLines.add(line);
            continue;
          }

          List<WordData> wordsInLeftColumn = [];
          List<WordData> wordsInRightColumn = [];
          for (var word in line.wordList!) {
            if (word.bounds.right < gapStart) {
              wordsInLeftColumn.add(word);
            } else {
              wordsInRightColumn.add(word);
            }
          }

          if (wordsInRightColumn.isNotEmpty) {
            // There are words in the right column
            rightColumnLines.add(
              LineData(
                text: wordsInRightColumn.map((w) => w.text).join(' '),
                fontSize: line.fontSize,
                bounds: Rect.fromLTRB(
                  wordsInRightColumn.first.bounds.left,
                  line.bounds!.top,
                  line.bounds!.right,
                  line.bounds!.bottom,
                ),
                fontStyle: line.fontStyle,
                lineIndex: line.lineIndex,
                wordList: wordsInRightColumn,
              ),
            );
          }
          if (wordsInLeftColumn.isNotEmpty) {
            leftColumnLines.add(
              LineData(
                text: wordsInLeftColumn.map((w) => w.text).join(' '),
                fontSize: line.fontSize,
                bounds: Rect.fromLTRB(
                  line.bounds!.left,
                  line.bounds!.top,
                  wordsInLeftColumn.last.bounds.right,
                  line.bounds!.bottom,
                ),
                fontStyle: line.fontStyle,
                lineIndex: line.lineIndex,
                wordList: wordsInLeftColumn,
              ),
            );
          }
        }

        // Save the reordered version (left column, then right column)
        pageLinesWithColumns[pageEntry.key] = [
          ...leftColumnLines,
          ...rightColumnLines,
        ];
      } else {
        hasColumns[pageEntry.key] = false;
      }
    }
  }

  List<double> _projectWord(
    double left,
    double right,
    List<double> projections,
  ) {
    if (projections.isEmpty) {
      return [left, right];
    }

    List<double> newProjections = [];
    int i = 0;
    bool addedNewInterval = false;

    while (i < projections.length) {
      double boundStart = projections[i];
      double boundEnd = projections[i + 1];

      if (!addedNewInterval) {
        // New interval ends before the existing interval
        if (right <= boundStart) {
          newProjections.add(left);
          newProjections.add(right);
          addedNewInterval = true;
        }

        // Check if we need to merge with the existing bound
        if (left < boundEnd && right > boundStart) {
          // Overlapping - merge by extending boundaries
          left = min(left, boundStart);
          right = max(right, boundEnd);
          i += 2;
          continue;
        }
      }
      // Add the existing bound
      newProjections.add(boundStart);
      newProjections.add(boundEnd);
      i += 2;
    }

    // Add the new interval if not yet added
    if (!addedNewInterval) {
      newProjections.add(left);
      newProjections.add(right);
    }

    return newProjections;
  }
}

class LineData {
  String text;
  final double? fontSize;
  final Rect? bounds;
  final List<PdfFontStyle>? fontStyle;
  final double? avgWordLength;
  final int? wordCount;
  final int lineIndex;
  int? avgSpaceBetweenWords;
  final List<WordData>? wordList;

  LineData({
    this.wordCount,
    required this.text,
    this.fontSize,
    this.bounds,
    this.fontStyle,
    required this.lineIndex,
    this.wordList,
    this.avgWordLength,
    this.avgSpaceBetweenWords,
  });

  int get pdfWordCount => wordList!.length;

  factory LineData.fromGlyphArray(int lineIndex, List<TextGlyph> glyphs) {
    Map<int, List<TextGlyph>> wordGlyphMap = {};
    int currentWordIndex = -1;
    double lastRightBound = 0.0;
    for (var glyph in glyphs) {
      // Check if glyph is a space
      if (glyph.text.trim().isEmpty) {
        continue; // Trim spaces
      }
      if ((glyph.bounds.left - lastRightBound) > spaceThreshold ||
          currentWordIndex == -1) {
        currentWordIndex++;
      }
      // Add glyph to the current word
      if (wordGlyphMap[currentWordIndex] == null) {
        wordGlyphMap[currentWordIndex] = [glyph];
      } else {
        wordGlyphMap[currentWordIndex]!.add(glyph);
      }
      lastRightBound = glyph.bounds.right;
    }

    // Create WordData list
    List<WordData> words = [];
    for (var entry in wordGlyphMap.entries) {
      words.add(WordData.fromGlyphArray(entry.key, entry.value));
    }

    double? fontSize;
    List<PdfFontStyle>? fontStyle;
    (fontSize, fontStyle) = _getFontAttributes(words);

    return LineData(
      lineIndex: lineIndex,
      text: words.map((w) => w.text).join(' '),
      fontSize: fontSize,
      fontStyle: fontStyle,
      bounds: _calculateBounds(glyphs),
      wordList: words,
    );
  }
}

class WordData {
  final String text;
  final double? fontSize;
  final Rect bounds;
  final List<PdfFontStyle>? fontStyle;
  final int wordIndex;
  final List<GlyphData> glyphList;

  WordData({
    required this.text,
    required this.fontSize,
    required this.bounds,
    required this.fontStyle,
    required this.glyphList,
    required this.wordIndex,
  });

  factory WordData.fromGlyphArray(int wordIndex, List<TextGlyph> glyphs) {
    double? fontSize;
    List<PdfFontStyle>? fontStyle;

    final glyphData = glyphs
        .asMap()
        .entries
        .map((e) => GlyphData.fromGlyph(e.key, e.value))
        .toList();

    (fontSize, fontStyle) = _getFontAttributes(glyphData);

    return WordData(
      wordIndex: wordIndex,
      text: glyphs.map((g) => g.text).join(),
      bounds: _calculateBounds(glyphs),
      fontSize: fontSize,
      fontStyle: fontStyle,
      glyphList: glyphData,
    );
  }
}

class GlyphData {
  final String text;
  final double fontSize;
  final Rect bounds;
  final List<PdfFontStyle> fontStyle;
  final int glyphIndex;

  GlyphData({
    required this.text,
    required this.fontSize,
    required this.bounds,
    required this.fontStyle,
    required this.glyphIndex,
  });

  factory GlyphData.fromGlyph(int glyphIndex, TextGlyph glyph) {
    return GlyphData(
      glyphIndex: glyphIndex,
      text: glyph.text,
      fontSize: glyph.fontSize,
      bounds: glyph.bounds,
      fontStyle: glyph.fontStyle,
    );
  }
}

Rect _calculateBounds(List<TextGlyph> glyphs) {
  if (glyphs.isEmpty) {
    return Rect.zero;
  }
  double left = glyphs.first.bounds.left;
  double top = glyphs.first.bounds.top;
  double right = glyphs.first.bounds.right;
  double bottom = glyphs.first.bounds.bottom;

  for (var glyph in glyphs) {
    if (glyph.bounds.left < left) {
      left = glyph.bounds.left;
    }
    if (glyph.bounds.top < top) {
      top = glyph.bounds.top;
    }
    if (glyph.bounds.right > right) {
      right = glyph.bounds.right;
    }
    if (glyph.bounds.bottom > bottom) {
      bottom = glyph.bounds.bottom;
    }
  }

  return Rect.fromLTRB(left, top, right, bottom);
}

(double?, List<PdfFontStyle>?) _getFontAttributes(List<dynamic> children) {
  if (children.isEmpty) {
    return (null, null);
  }

  bool allSameSize = children.every(
    (child) => child.fontSize == children.first.fontSize,
  );
  bool allSameStyle = children.every((child) {
    List<PdfFontStyle>? fontStyles = child.fontStyle;

    for (var style in fontStyles ?? []) {
      if (!children.every((c) => c.fontStyle?.contains(style) ?? false)) {
        return false;
      }
    }
    return true;
  });

  return (
    allSameSize ? children.first.fontSize : null,
    allSameStyle ? children.first.fontStyle : null,
  );
}
