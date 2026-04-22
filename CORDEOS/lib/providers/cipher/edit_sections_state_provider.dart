import 'package:flutter/foundation.dart';

/// Lightweight provider for managing EditSectionsScreen state
/// This allows tracking palette overlay and merge overlay without rebuilding expensive widget trees
class EditSectionsStateProvider extends ChangeNotifier {
  bool _paletteIsOpen = false;
  bool _mergeOverlayIsOpen = false;

  bool get paletteIsOpen => _paletteIsOpen;
  bool get mergeOverlayIsOpen => _mergeOverlayIsOpen;

  final List<int> _mergeSectionKeys = [];

  // ===== PALETTE METHODS =====
  void togglePalette() {
    _paletteIsOpen = !_paletteIsOpen;
    notifyListeners();
  }

  // ===== MERGE OVERLAY METHODS =====
  List<int> get mergeSectionKeys => _mergeSectionKeys;

  void enableMergeOverlay() {
    _mergeOverlayIsOpen = true;
    notifyListeners();
  }

  void disableMergeOverlay() {
    _mergeOverlayIsOpen = false;
    _mergeSectionKeys.clear();
    notifyListeners();
  }

  void toggleMergeSection(int sectionKey) {
    if (_mergeSectionKeys.contains(sectionKey)) {
      _mergeSectionKeys.remove(sectionKey);
    } else {
      _mergeSectionKeys.add(sectionKey);
    }
    notifyListeners();
  }

  // ===== GENERAL METHODS =====
  void resetState() {
    _paletteIsOpen = false;
    _mergeOverlayIsOpen = false;
    _mergeSectionKeys.clear();
    notifyListeners();
  }
}