import 'package:cordis/helpers/chords/chord_transposer.dart';
import 'package:cordis/models/ui/chord.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LineView extends StatelessWidget {
  final List<Chord> chords;
  final String line;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;

  const LineView({
    super.key,
    required this.chords,
    required this.line,
    required this.lyricStyle,
    required this.chordStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double xOffset;
        double yOffset;
        double endOfChord = 0.0;
        int lineNumber = 0;

        final ls = context.watch<LayoutSettingsProvider>();

        final transposer = ChordTransposer.fromKeys(
          originalKey: ls.originalKey,
          transposedKey: ls.transposedKey,
        );

        final chordPositions = <Widget>[];

        for (final chord in chords) {
          final String chordToShow = transposer.transposeChord(chord.name);
          (xOffset, yOffset, endOfChord, lineNumber) = chord
              .calculateOffsetForChord(
                lyricStyle,
                chordStyle,
                lineNumber,
                constraints.maxWidth,
                endOfChord,
              );

          chordPositions.add(
            Positioned(
              left: xOffset,
              top: yOffset,
              child: RepaintBoundary(
                child: Text(chordToShow, style: chordStyle),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              line,
              style: lyricStyle,
              textHeightBehavior: TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: false,
              ),
            ),
            ...chordPositions,
          ],
        );
      },
    );
  }
}
