import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:flutter/foundation.dart';
import 'package:cordis/services/import/image_import_service.dart';
import 'package:cordis/services/import/pdf_import_service.dart';

class ImportProvider extends ChangeNotifier {
  final PDFImportService _pdfService = PDFImportService();
  final ImageImportService _imageService = ImageImportService();

  /// Single ParsingCipher object that may contain multiple import variants
  ParsingCipher? _importedCipher;
  bool _isImporting = false;
  String? _selectedFile;
  String? _selectedFileName;
  String? _error;
  ImportType? _importType;
  ParsingStrategy? _parsingStrategy;
  ImportVariation? _importVariation;

  ParsingCipher? get importedCipher => _importedCipher;
  String? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFileName;
  bool get isImporting => _isImporting;
  String? get error => _error;
  ImportType? get importType => _importType;
  ParsingStrategy? get parsingStrategy => _parsingStrategy;
  ImportVariation? get importVariation => _importVariation;

  /// Sets the import type (text, pdf, image).
  void setImportType(ImportType type) {
    _importType = type;
  }

  /// Sets the parsing strategy.
  void setParsingStrategy(ParsingStrategy strategy) {
    _parsingStrategy = strategy;
    notifyListeners();
  }

  void setImportVariation(ImportVariation variation) {
    _importVariation = variation;
    notifyListeners();
  }

  /// Imports text based on the selected import type.
  /// For PDFs: creates multiple import variants (with/without columns) in a single ParsingCipher
  /// For text/images: creates a single import variant
  Future<void> importText({String? data}) async {
    if (_isImporting) return;

    _isImporting = true;
    _error = null;
    notifyListeners();

    try {
      switch (_importType) {
        case ImportType.text:
          // Text import: single import variant (textDirect)
          _importedCipher = ParsingCipher(
            result: ParsingResult(
              strategy: _parsingStrategy!,
              rawText: data ?? '',
            ),
            importType: ImportType.text,
          );
          break;

        case ImportType.pdf:
          // PDF import: multiple import variants (with/without columns)
          final pdfDocument = await _pdfService.extractTextWithFormatting(
            selectedFile!,
            selectedFileName!,
          );

          _importedCipher = ParsingCipher(
            importType: ImportType.pdf,
            result: ParsingResult(
              strategy: ParsingStrategy.pdfFormatting,
              rawText: '',
            ),
          );

          _importedCipher!.result.metadata['title'] = pdfDocument.documentName
              .split('.') // remove file extension
              .first;

          _importedCipher!.result.lines.addAll(
            _importVariation == ImportVariation.pdfWithColumns
                ? pdfDocument.pageLinesWithColumns[0]!
                : pdfDocument.pageLines[0]!,
          );
          break;

        case ImportType.image:
          await _imageService.extractText(selectedFile!);
          break;

        default:
          throw Exception('Import type not set');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// Sets the selected file name.
  void setSelectedFile(String fileName) {
    _selectedFile = fileName;
    notifyListeners();
  }

  /// Sets the selected file name.
  void setSelectedFileName(String fileName) {
    _selectedFileName = fileName;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFileName() {
    _selectedFileName = null;
    notifyListeners();
  }

  /// Clears any existing error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _importedCipher = null;
    _isImporting = false;
    _selectedFile = null;
    _selectedFileName = null;
    _error = null;
    _importType = null;
    _parsingStrategy = null;
    _importVariation = null;
    notifyListeners();
  }
}
