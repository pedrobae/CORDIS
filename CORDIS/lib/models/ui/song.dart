import 'package:flutter/material.dart';
import 'chord.dart';

int _minimumGap = 4;

class Song {
  final Map<int, String> linesMap; // Line number -> Lyrics
  final Map<int, List<Chord>> chordsMap; // Line number -> List of Chords
  bool hasPrecedingChord = false;
  double? precedingChordOffset;

  Song(this.linesMap, this.chordsMap) {
    _checkForPrecedingChord(const TextStyle());
  }

  Song copyWith({
    Map<int, String>? linesMap,
    Map<int, List<Chord>>? chordsMap,
    bool hasPrecedingChord = false,
    double? precedingChordOffset,
  }) {
    return Song(linesMap ?? this.linesMap, chordsMap ?? this.chordsMap);
  }

  void _checkForPrecedingChord(TextStyle chordStyle) {
    double precedingOffset = 0.0;
    for (int i = 0; i < linesMap.length; i++) {
      if (linesMap[i]!.isNotEmpty && linesMap[i]![0] == ' ') {
        // Found a line with space at the start, indicating preceding chord
        hasPrecedingChord = true;

        // Calculate offset of the preceding chords
        double totalWidth = 0.0;
        for (var chord in chordsMap[i]!) {
          if (chord.lyricsBefore.isEmpty) {
            totalWidth += (TextPainter(
              text: TextSpan(text: chord.name, style: chordStyle),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout(maxWidth: double.infinity, minWidth: 0)).width;

            totalWidth += _minimumGap;
          } else {
            break; // Stop at the first chord that has lyrics before it
          }
        }
        totalWidth -= _minimumGap; // Remove last gap

        if (totalWidth > precedingOffset) {
          precedingOffset = totalWidth;
        }
      }
    }

    if (hasPrecedingChord) {
      precedingChordOffset = precedingOffset;
    }
  }

  factory Song.fromChordPro(String? chordProText) {
    Map<int, String> linesMap = {};
    Map<int, List<Chord>> chordsMap = {};

    final linesRaw = chordProText?.split('\n') ?? [];

    for (int i = 0; i < linesRaw.length; i++) {
      String line = linesRaw[i].trim();
      // Extract chords and lyrics
      final chordPattern = RegExp(r'\[([^\]]+)\]');
      final matches = chordPattern.allMatches(line);

      // Adds the plain lyric to the linesMap
      String plainLyrics = line.replaceAll(chordPattern, '');
      linesMap[i] = plainLyrics;

      List<Chord> chords = [];
      int plainIndex = 0; // Tracks the position in plainLyrics

      for (final match in matches) {
        String chordName = match.group(1)!; // Actual Chord

        // Extract the lyrics before the chord in plain text
        String lyricsUpToMatch = line
            .substring(0, match.start)
            .replaceAll(chordPattern, '');
        plainIndex = lyricsUpToMatch.length;

        String lyricsBefore = plainLyrics.substring(0, plainIndex);

        // Find the next word after the chord
        int nextWordStart = plainIndex;
        int nextWordEnd = plainIndex;
        while (nextWordEnd < plainLyrics.length &&
            plainLyrics[nextWordEnd] != ' ') {
          nextWordEnd++;
        }
        String wordAfter = plainLyrics.substring(nextWordStart, nextWordEnd);

        // Add the chord to the list
        chords.add(Chord(chordName, lyricsBefore, wordAfter));
      }

      // Add the list of chords to the map
      if (chords.isNotEmpty) {
        chordsMap[i] = chords;
      }
    }

    return Song(linesMap, chordsMap);
  }

  String generateLyrics() {
    StringBuffer lyricsBuffer = StringBuffer();

    for (int i = 0; i < linesMap.length; i++) {
      String line = linesMap[i] ?? '';
      lyricsBuffer.writeln(line);
    }

    return lyricsBuffer.toString().trim();
  }

  String generateChordPro() {
    StringBuffer chordProBuffer = StringBuffer();

    int length = linesMap.length;
    if (chordsMap.length > length) {
      length = chordsMap.length;
    }

    for (int i = 0; i < length; i++) {
      String line = linesMap[i] ?? '';
      List<Chord> chords = chordsMap[i] ?? [];

      // Insert chords into the line
      int offset = 0;
      for (final chord in chords) {
        int insertPosition = chord.lyricsBefore.length + offset;
        if (insertPosition > line.length) {
          insertPosition = line.length;
        }
        line =
            '${line.substring(0, insertPosition)}[${chord.name}]${line.substring(insertPosition)}';

        offset += chord.name.length + 2;
      }

      chordProBuffer.writeln(line);
    }

    return chordProBuffer.toString().trim();
  }
}
