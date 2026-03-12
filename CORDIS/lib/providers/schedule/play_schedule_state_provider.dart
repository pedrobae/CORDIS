import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:flutter/foundation.dart';

/// Lightweight provider for managing PlayScheduleScreen state
/// This allows item navigation without rebuilding expensive widget trees
class PlayScheduleStateProvider extends ChangeNotifier {
  int _currentItemIndex = 0;
  bool _isVertPlay = false;
  bool _showSettings = false;
  List<PlaylistItem> _items = [];

  int get currentItemIndex => _currentItemIndex;
  bool get isVertPlay => _isVertPlay;
  bool get showSettings => _showSettings;
  PlaylistItem? get currentItem => _items.isNotEmpty ? _items[_currentItemIndex] : null;
  PlaylistItem? get nextItem => (_currentItemIndex < _items.length - 1) ? _items[_currentItemIndex + 1] : null;
  int get itemCount => _items.length;

  PlaylistItem? getItemAt(int index) {
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }
  

  void setCurrentItemIndex(int index) {
    if (_currentItemIndex != index) {
      _currentItemIndex = index;
      notifyListeners();
    }
  }

  void toggleSettings() {
    _showSettings = !_showSettings;
    notifyListeners();
  }

  void setVertPlay(bool isVertPlay) {
    _isVertPlay = isVertPlay;
    notifyListeners();
  }

  void setShowSettings(bool value) {
    if (_showSettings != value) {
      _showSettings = value;
      notifyListeners();
    }
  }

  void setItems(List<PlaylistItem> items) {
    _items = items;
    _currentItemIndex = 0; // Reset to first item when new list is set
    notifyListeners();
  }


  void reset() {
    _currentItemIndex = 0;
    _showSettings = false;
    _items = [];
    notifyListeners();
  }
}
