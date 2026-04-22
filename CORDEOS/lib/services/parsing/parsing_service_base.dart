import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/services/parsing/chord_line_parser.dart';
import 'package:cordeos/services/parsing/section_parser.dart';

class ParsingServiceBase {
  final ChordLineParser chordLineParser = ChordLineParser();
  final SectionParser sectionParser = SectionParser();

  void parse(ParsingResult result) {
    parseSections(result);
    parseChords(result);
  }

  void parseSections(ParsingResult result) {
    switch (result.strategy) {
      case ParsingStrategy.doubleNewLine:
        sectionParser.parseByEmptyLine(result);
        break;
      case ParsingStrategy.sectionLabels:
        sectionParser.parseBySectionLabels(result);
        break;
      case ParsingStrategy.pdfFormatting:
        sectionParser.parseByPdfFormatting(result);
        break;
    }
  }

  void parseChords(ParsingResult result) {
    switch (result.strategy) {
      case ParsingStrategy.doubleNewLine:
      case ParsingStrategy.sectionLabels:
        chordLineParser.parseBySimpleText(result);
        break;
      case ParsingStrategy.pdfFormatting:
        chordLineParser.parseByPdfFormatting(result);
        break;
    }
  }

  /// ----- PRE-PROCESSING HELPERS ------
  void separateLines(ParsingResult result) {
    final rawLines = result.rawText.split('\n');
    for (var i = 0; i < rawLines.length; i++) {
      var line = rawLines[i];
      // Split line text into words using whitespace as delimiter
      List<String> words = line.split(RegExp(r'\s+')).toList();

      result.lines.add(
        LineData(
          wordCount: words.length,
          text: line,
          lineIndex: i,
        ),
      );
    }
  }

  VersionDto buildVersionFromResult(ParsingResult result) {
    return VersionDto(
      sections: result.parsedSections,
      songStructure: result.songStructure,
      bpm: result.metadata['bpm'] ?? 0,
      versionName: 'Imported',
      duration: result.metadata['duration'] ?? 0,
      title: result.metadata['title'] ?? 'Unknown Title',
      author: result.metadata['artist'] ?? 'Unknown Artist',
      language: result.metadata['language'] ?? '',
      originalKey: '',
      tags: result.metadata['tags'] != null
          ? List<String>.from(result.metadata['tags'])
          : [],

    );
  }
}
