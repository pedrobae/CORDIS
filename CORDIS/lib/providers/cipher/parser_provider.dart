import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/services/parsing/parsing_service_base.dart';
import 'package:flutter/material.dart';

class ParserProvider extends ChangeNotifier {
  final ParsingServiceBase _parsingService = ParsingServiceBase();

  ParsingCipher? _cipher;
  ParsingCipher? get cipher => _cipher;

  // Chosen Cipher after parsing
  Cipher? _parsedCipher;
  Cipher? get parsedCipher => _parsedCipher;

  bool _isParsing = false;
  bool get isParsing => _isParsing;

  String _error = '';
  String get error => _error;

  Future<void> parseCipher(ParsingCipher importedCipher) async {
    if (_isParsing) return;

    _cipher = importedCipher;
    _isParsing = true;
    _error = '';
    notifyListeners();

    try {
      // ===== PRE-PROCESSING STEPS =====
      switch (importedCipher.importType) {
        case ImportType.text:
          // Calculate line metrics
          _parsingService.calculateLines(importedCipher.result);
          break;
        case ImportType.pdf:
          // Average character spacing and font style analysis
          _parsingService.preProcessPdf(importedCipher.result);
          break;
        case ImportType.image:
          // Image specific parsing can be added here
          break;
      }

      /// ===== PARSING STEPS =====
      _parsingService.parse(_cipher!.result);

      // Build domain Cipher from parsed sections
      _parsedCipher = _parsingService.buildCipherFromParsedImportVariant(
        _cipher!.result,
      );

      _isParsing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error during parsing: $e';
      _isParsing = false;
      notifyListeners();
      return;
    }
  }
}
