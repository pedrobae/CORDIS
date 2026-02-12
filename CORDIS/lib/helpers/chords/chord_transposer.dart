import 'package:cordis/helpers/chords/chords.dart';

class ChordTransposer extends ChordHelper {
  static const List<String> flatKeys = [
    'F',
    'Bb',
    'Eb',
    'Ab',
    'Db',
    'Gb',
    'Cb',
  ];

  // Pre-sorted list of all chord roots (longest first for proper parsing)
  static const List<String> allChordRoots = [
    'C#',
    'Db',
    'D#',
    'Eb',
    'F#',
    'Gb',
    'G#',
    'Ab',
    'A#',
    'Bb', // 2-char roots first
    'C', 'D', 'E', 'F', 'G', 'A', 'B', // 1-char roots second
  ];

  final String originalKey;
  final int transposeValue;

  ChordTransposer({required this.originalKey, required this.transposeValue});

  // Calculate the transposed key first, then determine if we should use flats
  String get transposedKey {
    String tempKey = transpose(originalKey, transposeValue, useFlats: true);
    String key = '';
    tempKey == 'Gb' ? key = 'F#' : key = tempKey;
    return key;
  }

  bool get useFlats => flatKeys.contains(transposedKey);

  String transposeChord(String chord) {
    // Parse chord root first
    String? root;
    String remainingSuffix = '';

    // Find the longest matching root (handles both C# and C correctly)
    for (final r in allChordRoots) {
      if (chord.startsWith(r)) {
        root = r;
        remainingSuffix = chord.substring(r.length);
        break;
      }
    }
    if (root == null) return chord;

    // Parse slash chord if present
    String? bass;
    String chordSuffix = remainingSuffix;

    if (remainingSuffix.contains('/')) {
      final slashIndex = remainingSuffix.indexOf('/');
      chordSuffix = remainingSuffix.substring(0, slashIndex);
      final bassPart = remainingSuffix.substring(slashIndex + 1);

      // Find bass note (should match exactly or be at the start)
      for (final r in allChordRoots) {
        if (bassPart == r || bassPart.startsWith(r)) {
          bass = r;
          break;
        }
      }
    }

    // Transpose root and bass
    String transposedRoot = transpose(root, transposeValue, useFlats: useFlats);
    String result = transposedRoot + chordSuffix;

    if (bass != null) {
      String transposedBass = transpose(
        bass,
        transposeValue,
        useFlats: useFlats,
      );
      result += '/$transposedBass';
    }

    return result;
  }
}
