import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:flutter/foundation.dart';

/// Lightweight provider for managing PlayScheduleScreen state
/// This allows tab navigation without rebuilding expensive widget trees
class PlayScheduleStateProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _showSettings = false;
  List<PlaylistItem> _items = [];

  int get currentTabIndex => _currentTabIndex;
  bool get showSettings => _showSettings;
  PlaylistItem? get currentItem => _items.isNotEmpty ? _items[_currentTabIndex] : null;
  PlaylistItem? get nextItem => (_currentTabIndex < _items.length - 1) ? _items[_currentTabIndex + 1] : null;
  int get itemCount => _items.length;
  

  void setCurrentTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void toggleSettings() {
    _showSettings = !_showSettings;
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
    _currentTabIndex = 0; // Reset to first item when new list is set
    notifyListeners();
  }

  void reset() {
    _currentTabIndex = 0;
    _showSettings = false;
    _items = [];
  }
}
