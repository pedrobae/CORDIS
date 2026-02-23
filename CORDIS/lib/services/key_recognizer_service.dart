import 'package:cordis/repositories/cloud/version_repository.dart';
import 'package:cordis/repositories/local/cipher_repository.dart';
import 'package:cordis/repositories/local/section_repository.dart';
import 'package:cordis/repositories/local/version_repository.dart';

class KeyRecognizerService {
  static const List<String> _keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final _cipherRepo = CipherRepository();
  final _localVersionRepo = LocalVersionRepository();
  final _cloudVersionRepo = CloudVersionRepository();
  final _sectionRepo = SectionRepository();

  /// Collects all chords and select a music key based on them
  /// The key is selected based on the most common chords, and the one with the highest score based on the chord's position in the key (1st, 3rd, 5th, etc)
  /// If there are no chords, or the chords don't match any key, it returns C
  /// The score is calculated based on the position of the chord in the key, and the number of times it appears in the chords list

  /// Collects all chords of a cipherID and select a music key based on them
  String recognizeKeyLocal(int cipherID) {
    final cipher = _cipherRepo.getCipherById(cipherID);

    String key = 'C';

    return key;
  }
}
