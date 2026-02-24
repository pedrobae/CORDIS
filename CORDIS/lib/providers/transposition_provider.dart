import 'package:flutter/material.dart';
import 'package:cordis/helpers/chords/chords.dart';

class TranspositionProvider extends ChangeNotifier {
  final List<String> keyList = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  List<String> get chordRoots => [
    'C',
    useSharp ? 'C#' : 'Db',
    'D',
    useSharp ? 'D#' : 'Eb',
    'E',
    'F',
    useSharp ? 'F#' : 'Gb',
    'G',
    useSharp ? 'G#' : 'Ab',
    'A',
    useSharp ? 'A#' : 'Bb',
    'B',
  ];

  static const List<String> _allRoots = [
    'C#',
    'Db',
    'D#',
    'Eb',
    'F#',
    'Gb',
    'G#',
    'Ab',
    'A#',
    'Bb',
    'C', 'D', 'E', 'F', 'G', 'A', 'B', // Ordered to match semitone steps
  ];

  String _originalKey = '';
  String? _transposedKey;

  bool get useSharp => _transposedKey != null && _transposedKey! == 'F#';

  int get _transposeValue {
    if (_transposedKey == null) return 0;

    int indexOriginal = chordRoots.indexOf(_originalKey);
    int indexTransposed = chordRoots.indexOf(_transposedKey!);

    if (indexOriginal == -1 || indexTransposed == -1) return 0;

    return (indexTransposed - indexOriginal) % 12;
  }

  String get originalKey => _originalKey;
  String? get transposedKey => _transposedKey;

  void setTransposedKey(String? newKey) {
    _transposedKey = newKey;
    notifyListeners();
  }

  void setOriginalKey(String newKey) {
    _originalKey = newKey;
    _transposedKey = null;
    notifyListeners();
  }

  void clearTransposer() {
    _transposedKey = null;
    _originalKey = '';
    notifyListeners();
  }

  void transposeUp() {
    int index = chordRoots.indexOf(_transposedKey ?? _originalKey);
    if (index == -1) return;
    int newIndex = (index + 1) % chordRoots.length;
    _transposedKey = chordRoots[newIndex];
    notifyListeners();
  }

  void transposeDown() {
    int index = chordRoots.indexOf(_transposedKey ?? _originalKey);
    if (index == -1) return;
    int newIndex = index - 1;
    if (newIndex < 0) newIndex += chordRoots.length;
    _transposedKey = chordRoots[newIndex];
    notifyListeners();
  }

  String transposeChord(String chord) {
    // Parse chord root first
    String? root;
    String remainingSuffix = '';

    // Find the longest matching root (handles both C# and C correctly)
    for (final r in chordRoots) {
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
      for (final r in _allRoots) {
        if (bassPart == r || bassPart.startsWith(r)) {
          bass = r;
          break;
        }
      }
    }

    // Transpose root and bass
    String transposedRoot = ChordHelper().transpose(
      root,
      _transposeValue,
      useFlats: !useSharp,
    );
    String result = transposedRoot + chordSuffix;

    if (bass != null) {
      String transposedBass = ChordHelper().transpose(
        bass,
        _transposeValue,
        useFlats: !useSharp,
      );
      result += '/$transposedBass';
    }

    return result;
  }
}
