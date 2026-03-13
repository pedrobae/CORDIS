import 'dart:async';

import 'package:cordis/services/settings_service.dart';
import 'package:flutter/material.dart';

enum AutoScrollMode { tab, vertical }

class AutoScrollProvider extends ChangeNotifier {
  AutoScrollProvider() {
    _loadSettings();
  }

  double scrollSpeed = 1.0;
  static const int _millisecondsPerLine = 1500;

  bool isAutoScrolling = false;
  bool scrollModeEnabled = false;
  AutoScrollMode _mode = AutoScrollMode.tab;
  int _activeVerticalItemIndex = 0;

  late final ValueNotifier<int> currentSectionIndex = ValueNotifier(0);

  Map<int, GlobalKey> get currentItemSectionKeys =>
      _vertSectionKeys[_activeVerticalItemIndex] ?? {};

  int get _tabSectionCount => _tabSectionKeys.length;
  int get _verticalSectionCount => currentItemSectionKeys.length;
  bool get isVerticalMode => _mode == AutoScrollMode.vertical;

  Timer? autoScrollTimer;
  Timer? _updateTimer;
  DateTime? _timerStartTime;

  final Map<int, GlobalKey> _tabSectionKeys = {};
  final Map<int, GlobalKey> _verticalItemKeys = {};
  final Map<int, Map<int, GlobalKey>> _vertSectionKeys = {};

  final Map<int, int> _tabSectionLineCount = {};
  final Map<int, Map<int, int>> _vertSectionLineCount = {};

  // ===== SETTINGS METHODS =====
  /// Gets settings from SettingsService and updates provider state
  Future<void> _loadSettings() async {
    currentSectionIndex.value = 0;
    _activeVerticalItemIndex = 0;
    scrollModeEnabled = SettingsService.getAutoScrollEnabled();
    scrollSpeed = SettingsService.getAutoScrollSpeed();
    notifyListeners();
  }

  /// Updates scroll speed and saves to settings
  void setScrollSpeed(double value) {
    scrollSpeed = value;
    SettingsService.setAutoScrollSpeed(value);
    notifyListeners();
  }

  void toggleScrollMode() {
    scrollModeEnabled = !scrollModeEnabled;
    stopAutoScroll();
    SettingsService.setAutoScrollEnabled(scrollModeEnabled);
    notifyListeners();
  }

  void setPlayMode({required bool isVertPlay}) {
    final nextMode = isVertPlay ? AutoScrollMode.vertical : AutoScrollMode.tab;
    if (_mode == nextMode) return;

    stopAutoScroll();
    _mode = nextMode;
    currentSectionIndex.value = 0;
    _activeVerticalItemIndex = 0;
    notifyListeners();
  }

  void setActiveItemIndex(int index) {
    if (_activeVerticalItemIndex == index) return;

    _activeVerticalItemIndex = index;
    final sectionCount = _verticalSectionCount;
    if (currentSectionIndex.value >= sectionCount) {
      currentSectionIndex.value = 0;
    }
  }

  GlobalKey registerTabSection(int index) {
    return _tabSectionKeys.putIfAbsent(index, GlobalKey.new);
  }

  void setTabSectionLineCount(int index, int lineCount) {
    _tabSectionLineCount[index] = lineCount;
  }

  GlobalKey registerVerticalItem(int itemIndex) {
    return _verticalItemKeys.putIfAbsent(itemIndex, GlobalKey.new);
  }

  GlobalKey registerVerticalSection(int itemIndex, int sectionIndex) {
    final itemSections = _vertSectionKeys.putIfAbsent(itemIndex, () => {});
    return itemSections.putIfAbsent(sectionIndex, GlobalKey.new);
  }

  void setVerticalSectionLineCount(
    int itemIndex,
    int sectionIndex,
    int lineCount,
  ) {
    final itemLineCounts = _vertSectionLineCount.putIfAbsent(
      itemIndex,
      () => {},
    );
    itemLineCounts[sectionIndex] = lineCount;
  }

  // ===== AUTO SCROLL METHODS =====
  /// Toggles auto-scroll on/off and starts/stops timer accordingly
  void toggleAutoScroll() {
    if (!scrollModeEnabled || isAutoScrolling) {
      stopAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  void toggleAutoScrollTabs() {
    toggleAutoScroll();
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _timerStartTime = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  /// Starts the auto-scroll timer
  /// Which scrolls through sections at intervals based on line count and scrollSpeed
  void startAutoScroll() {
    if (!scrollModeEnabled) return;
    if (isAutoScrolling) return;
    if (_activeSectionCount == 0) return;

    isAutoScrolling = true;
    notifyListeners();

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      notifyListeners();
    });

    _scheduleNextSectionScroll();
  }

  void startAutoScrollTabs() {
    startAutoScroll();
  }

  /// Schedules the next section scroll based on current section's line count
  /// Uses a single-shot timer that recalculates duration for each section
  void _scheduleNextSectionScroll() {
    if (_activeSectionCount == 0 || !isAutoScrolling) return;

    final lineCount = _activeLineCounts[currentSectionIndex.value];
    if (lineCount == null || lineCount <= 0) return;

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * lineCount ~/ scrollSpeed).toInt(),
    );

    _timerStartTime = DateTime.now();

    // Cancel existing timer and schedule next section scroll
    autoScrollTimer?.cancel();
    autoScrollTimer = Timer(durationPerSection, () {
      if (_activeSectionCount == 0 || !isAutoScrolling) return;

      // Move to next section
      if (currentSectionIndex.value < _activeSectionCount - 1) {
        currentSectionIndex.value++;
        if (isVerticalMode) {
          scrollToItemSection(
            itemIndex: _activeVerticalItemIndex,
            sectionIndex: currentSectionIndex.value,
          );
        } else {
          scrollToSectionTabs(currentSectionIndex.value);
        }
        _scheduleNextSectionScroll(); // Schedule next with its line count
      } else {
        // Stop at the end
        stopAutoScroll();
      }
    });
  }

  /// Scrolls to the section at the given index using its GlobalKey
  void scrollToSectionTabs(int index) {
    if (index >= _tabSectionCount) return;

    final sectionKey = _tabSectionKeys[index];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    currentSectionIndex.value = index;
  }

  /// Scrolls to the section at the given indexes using its GlobalKey
  void scrollToItemSection({
    required int itemIndex,
    required int sectionIndex,
  }) {
    if (_vertSectionKeys[itemIndex] == null) return;
    if (_vertSectionKeys[itemIndex]![sectionIndex] == null) return;

    final sectionKey = _vertSectionKeys[itemIndex]![sectionIndex];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    _activeVerticalItemIndex = itemIndex;
    currentSectionIndex.value = sectionIndex;
  }

  // ===== HELPER METHODS =====
  /// Returns a value between 0.0 and 1.0 representing progress to next section scroll
  double get timerProgress {
    if (autoScrollTimer == null ||
        !autoScrollTimer!.isActive ||
        _timerStartTime == null) {
      return 0.0;
    }

    final lineCount = _activeLineCounts[currentSectionIndex.value];
    if (lineCount == null || lineCount <= 0) {
      return 0.0;
    }

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * lineCount ~/ scrollSpeed).toInt(),
    );

    // Calculate elapsed time since timer started
    final elapsed = DateTime.now().difference(_timerStartTime!);
    final elapsedMs = elapsed.inMilliseconds;

    // Return progress within current interval (0.0 to 1.0)
    return (elapsedMs % durationPerSection.inMilliseconds) /
        durationPerSection.inMilliseconds;
  }

  /// Calculates the current section index based on the scroll offset
  int? syncTabSectionFromViewport(double viewportHeight) {
    final bestMatch = _findBestSectionIndex(
      sectionKeys: _tabSectionKeys,
      viewportHeight: viewportHeight,
      minFactor: 0.10,
      maxFactor: 0.30,
      targetFactor: 0.20,
    );

    if (bestMatch == null) return null;

    currentSectionIndex.value = bestMatch;
    return bestMatch;
  }

  /// Calculates the current section index based on the scroll offset VERT PLAY
  ({int itemIndex, int sectionIndex})? syncVerticalSectionFromViewport(
    double viewportHeight,
  ) {
    ({int itemIndex, int sectionIndex, double distance})? bestMatch;

    for (final itemEntry in _vertSectionKeys.entries) {
      for (final sectionEntry in itemEntry.value.entries) {
        final sectionContext = sectionEntry.value.currentContext;
        if (sectionContext == null) continue;

        final box = sectionContext.findRenderObject() as RenderBox?;
        if (box == null) continue;

        final sectionTop = box.localToGlobal(Offset.zero).dy;
        if (sectionTop < viewportHeight * 0.15 ||
            sectionTop > viewportHeight * 0.30) {
          continue;
        }

        final distance = (sectionTop - viewportHeight * 0.20).abs();
        if (bestMatch == null || distance < bestMatch.distance) {
          bestMatch = (
            itemIndex: itemEntry.key,
            sectionIndex: sectionEntry.key,
            distance: distance,
          );
        }
      }
    }

    if (bestMatch == null) return null;

    _activeVerticalItemIndex = bestMatch.itemIndex;
    currentSectionIndex.value = bestMatch.sectionIndex;
    return (
      itemIndex: bestMatch.itemIndex,
      sectionIndex: bestMatch.sectionIndex,
    );
  }

  int? syncVerticalItemFromViewport(double viewportHeight) {
    ({int itemIndex, double distance})? bestMatch;

    for (final entry in _verticalItemKeys.entries) {
      final itemContext = entry.value.currentContext;
      if (itemContext == null) continue;

      final box = itemContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final itemTop = box.localToGlobal(Offset.zero).dy;
      final itemBottom = itemTop + box.size.height;

      if (itemTop > viewportHeight * 0.10 && itemTop < viewportHeight * 0.30) {
        final distance = (itemTop - viewportHeight * 0.20).abs();
        if (bestMatch == null || distance < bestMatch.distance) {
          bestMatch = (itemIndex: entry.key, distance: distance);
        }
      }

      if (itemBottom > viewportHeight * 0.40 &&
          itemBottom < viewportHeight * 0.60) {
        final distance = (itemBottom - viewportHeight * 0.50).abs();
        if (bestMatch == null || distance < bestMatch.distance) {
          bestMatch = (itemIndex: entry.key, distance: distance);
        }
      }
    }

    if (bestMatch == null) return null;

    _activeVerticalItemIndex = bestMatch.itemIndex;
    return bestMatch.itemIndex;
  }

  Map<int, int> get _activeLineCounts => isVerticalMode
      ? (_vertSectionLineCount[_activeVerticalItemIndex] ?? {})
      : _tabSectionLineCount;

  int get _activeSectionCount =>
      isVerticalMode ? _verticalSectionCount : _tabSectionCount;

  /// Clears cache
  void clearCache({bool resetItemIndex = true}) {
    _tabSectionKeys.clear();
    _tabSectionLineCount.clear();
    _verticalItemKeys.clear();
    _vertSectionKeys.clear();
    _vertSectionLineCount.clear();
    currentSectionIndex.value = 0;
    if (resetItemIndex) {
      _activeVerticalItemIndex = 0;
    }
    _updateTimer?.cancel();
    _timerStartTime = null;
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  // ===== CLEANUP =====
  @override
  void dispose() {
    autoScrollTimer?.cancel();
    currentSectionIndex.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  int? _findBestSectionIndex({
    required Map<int, GlobalKey> sectionKeys,
    required double viewportHeight,
    required double minFactor,
    required double maxFactor,
    required double targetFactor,
  }) {
    ({int index, double distance})? bestMatch;

    for (final entry in sectionKeys.entries) {
      final sectionContext = entry.value.currentContext;
      if (sectionContext == null) continue;

      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final sectionTop = box.localToGlobal(Offset.zero).dy;
      if (sectionTop < viewportHeight * minFactor ||
          sectionTop > viewportHeight * maxFactor) {
        continue;
      }

      final distance = (sectionTop - viewportHeight * targetFactor).abs();
      if (bestMatch == null || distance < bestMatch.distance) {
        bestMatch = (index: entry.key, distance: distance);
      }
    }

    return bestMatch?.index;
  }
}
