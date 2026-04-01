import 'package:flutter/foundation.dart';

/// Lightweight provider for managing EditSectionsScreen state
/// This allows tracking palette overlay and merge overlay without rebuilding expensive widget trees
class EditSectionsStateProvider extends ChangeNotifier {
  bool _paletteIsOpen = false;
  bool _mergeOverlayIsOpen = false;

  bool get paletteIsOpen => _paletteIsOpen;
  bool get mergeOverlayIsOpen => _mergeOverlayIsOpen;

  final List<String> _mergeSectionCodes = [];

  // ===== PALETTE METHODS =====
  void togglePalette() {
    _paletteIsOpen = !_paletteIsOpen;
    notifyListeners();
  }

  // ===== MERGE OVERLAY METHODS =====
  List<String> get mergeSectionCodes => _mergeSectionCodes;

  void enableMergeOverlay() {
    _mergeOverlayIsOpen = true;
    notifyListeners();
  }

  void disableMergeOverlay() {
    _mergeOverlayIsOpen = false;
    _mergeSectionCodes.clear();
    notifyListeners();
  }

  void toggleMergeSection(String sectionCode) {
    if (_mergeSectionCodes.contains(sectionCode)) {
      _mergeSectionCodes.remove(sectionCode);
    } else {
      _mergeSectionCodes.add(sectionCode);
    }
    notifyListeners();
  }

  // ===== GENERAL METHODS =====
  void resetState() {
    _paletteIsOpen = false;
    _mergeOverlayIsOpen = false;
    _mergeSectionCodes.clear();
    notifyListeners();
  }
}