import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/repositories/local/section_repository.dart';
import 'package:cordis/repositories/local/version_repository.dart';

class KeyRecognizerService {
  // Pre-sorted list of all chord roots (longest first for proper parsing)
  static const List<String> _keys = [
    'C', 'D', 'E', 'F', 'G', 'A', 'B', // 1-char roots second
  ];

  static const List<String> _flatKeys = ['Bb', 'Eb', 'Ab', 'Db', 'Gb'];
  static const List<String> _sharpKeys = ['C#', 'D#', 'F#', 'G#', 'A#'];

  final _localVersionRepo = LocalVersionRepository();
  final _sectionRepo = SectionRepository();

  /// Collects all chords of a cipherID and select a music key based on them
  Future<String> recognizeKeyLocal(int cipherID) async {
    final version = await _localVersionRepo.getOldestVersionOfCipher(cipherID);

    final sections = await _sectionRepo.getSections(version.id!);

    List<String> chords = [];
    for (var section in sections.values) {
      final text = section.contentText;
      final chord = StringBuffer();
      bool inChord = false;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (inChord) {
          if (char == ']') {
            inChord = false;
            chords.add(chord.toString());
            chord.clear();
          } else {
            chord.write(char);
          }
        } else {
          if (char == '[') {
            inChord = true;
          }
        }
      }
    }
    return _extractKey(chords);
  }

  /// Collects all chords of a Cloud Version and select a music key based on them
  Future<String> recognizeKeyCloud(VersionDto version) async {
    List<String> chords = [];
    for (var section in version.sections.values) {
      final text = section['contentText'] as String;
      final chord = StringBuffer();
      bool inChord = false;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (inChord) {
          if (char == ']') {
            inChord = false;
            chords.add(chord.toString());
            chord.clear();
          } else {
            chord.write(char);
          }
        } else {
          if (char == '[') {
            inChord = true;
          }
        }
      }
    }
    return _extractKey(chords);
  }

  /// Calculates the key based on the chords of a cipher, and updates the cipher with the new key
  /// Returns the new key
  String _extractKey(List<String> chords) {
    {
      Map<String, int> chordCounts = {};
      for (var chord in chords) {
        String root = chord.split(RegExp(r'[mM7]'))[0];

        chordCounts[root] = (chordCounts[root] ?? 0) + 1;
      }

      int flatCount = 0;
      int sharpCount = 0;
      for (var chord in chordCounts.entries) {
        if (chord.key.contains('b')) {
          flatCount += chord.value;
        } else if (chord.key.contains('#')) {
          sharpCount += chord.value;
        }
      }

      bool isFlatKey = flatCount > sharpCount;

      Map<String, int> keyScores = {};
      for (var key in [
        ..._keys,
        if (isFlatKey) ..._flatKeys,
        if (!isFlatKey) ..._sharpKeys,
      ]) {
        int score = 0;
        for (var chord in chordCounts.keys) {
          int position = _getChordPositionInKey(chord, key, isFlatKey);
          if (position != -1) {
            score += (4 - position) * chordCounts[chord]!;
          }
        }
        keyScores[key] = score;
      }

      return keyScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
  }

  /// Calculates the position of a chord in a key, based on the circle of fifths
  /// Returns -1 if the chord is not in the key
  int _getChordPositionInKey(String chord, String key, bool isFlatKey) {
    List<String> circleOfFifths = [
      'C',
      if (isFlatKey) 'Db' else 'C#',
      'D',
      if (isFlatKey) 'Eb' else 'D#',
      'E',
      'F',
      if (isFlatKey) 'Gb' else 'F#',
      'G',
      if (isFlatKey) 'Ab' else 'G#',
      'A',
      if (isFlatKey) 'Bb' else 'A#',
      'B',
    ];

    int keyIndex = circleOfFifths.indexOf(key);
    if (keyIndex == -1) return -1;

    List<String> keyChords = [
      circleOfFifths[keyIndex], // I
      circleOfFifths[(keyIndex + 2) % 12], // ii
      circleOfFifths[(keyIndex + 4) % 12], // iii
      circleOfFifths[(keyIndex + 5) % 12], // IV
      circleOfFifths[(keyIndex + 7) % 12], // V
      circleOfFifths[(keyIndex + 9) % 12], // vi
    ];

    return keyChords.indexOf(chord);
  }
}
