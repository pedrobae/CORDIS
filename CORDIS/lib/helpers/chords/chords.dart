class ChordHelper {
  const ChordHelper();

  static const List<String> keyList = [
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

  static const List<String> allRoots = [
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

  List<String> getChordRoots(bool useFlats) => [
    'C',
    useFlats ? 'Db' : 'C#',
    'D',
    useFlats ? 'Eb' : 'D#',
    'E',
    'F',
    useFlats ? 'Gb' : 'F#',
    'G',
    useFlats ? 'Ab' : 'G#',
    'A',
    useFlats ? 'Bb' : 'A#',
    'B',
  ];

  /// Generate chords for the current key
  List<String> getChordsForKey(String key) {
    final Map<String, List<String>> keyChords = {
      'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
      'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
      'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
      'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
      'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
      'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
      'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim'],
      // flat keys
      'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
      'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
      'Ab': ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'],
      'Db': ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim'],
      'Gb': ['Gb', 'Abm', 'Bbm', 'Cb', 'Db', 'Ebm', 'Fdim'],
    };

    // Return chords for key, or default C major if not found
    return keyChords[key] ?? keyChords['C']!;
  }

  List<String> getVariationsForChord(String chord, int index) {
    bool useFlats;
    if (chord.contains('b') || chord.contains('F')) {
      useFlats = true;
    } else {
      useFlats = false;
    }

    switch (index) {
      case 0:
        return [
          '$chord/${transpose(chord, 4, useFlats: useFlats)}',
          '$chord/${transpose(chord, 7, useFlats: useFlats)}',
          '${chord}maj7',
          '${chord}9',
        ];
      case 1:
      case 2:
      case 5:
        return ['${chord}7', minorToMajor(chord), '${minorToMajor(chord)}7'];
      case 3:
        return [
          '$chord/${transpose(chord, 4, useFlats: useFlats)}',
          '$chord/${transpose(chord, 7, useFlats: useFlats)}',
          '${chord}maj7',
          '$chord/${transpose(chord, 2, useFlats: useFlats)}',
          '${chord}9',
          '${chord}m',
        ];
      case 4:
        return [
          '${chord}7',
          '$chord/${transpose(chord, 4, useFlats: useFlats)}',
          '$chord/${transpose(chord, 7, useFlats: useFlats)}',
          '${chord}9',
          '${chord}m',
        ];
      case 6:
        return [
          '${dimToMajor(chord)}ø',
          '${dimToMajor(chord)}m',
          dimToMajor(chord),
          '${dimToMajor(chord)}m/${transpose(dimToMajor(chord), 3, useFlats: useFlats)}',
        ];
      default:
        return [];
    }
  }

  String transpose(String chord, int value, {required bool useFlats}) {
    final chromatic = getChordRoots(useFlats);
    int rootIndex = chromatic.indexOf(chord);
    if (rootIndex == -1) return chord;
    int newIndex = (rootIndex + value) % chromatic.length;
    if (newIndex < 0) newIndex += chromatic.length;
    return chromatic[newIndex];
  }

  String minorToMajor(String chord) {
    if (chord.endsWith('m')) {
      return chord.substring(0, chord.length - 1);
    }
    return chord;
  }

  String dimToMajor(String chord) {
    if (chord.endsWith('dim')) {
      return chord.substring(0, chord.length - 3);
    }
    return chord;
  }
}
