import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LayoutSettingsProvider extends ChangeNotifier {
  double fontSize = 16;
  String fontFamily = 'OpenSans';
  Color chordColor = const Color.fromARGB(255, 0, 0, 0);
  int columnCount = 1;
  bool showChords = true;
  bool showLyrics = true;
  bool showAnnotations = true;
  bool showTransitions = true;
  bool showTextSections = true;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    fontSize = SettingsService.getFontSize();
    fontFamily = SettingsService.getFontFamily();
    chordColor = SettingsService.getChordColor();
    columnCount = SettingsService.getColumnCount();
    showChords = SettingsService.getShowChords();
    showLyrics = SettingsService.getShowLyrics();
    showAnnotations = SettingsService.getShowNotes();
    showTransitions = SettingsService.getShowTransitions();
    showTextSections = SettingsService.getShowTextSections();
    notifyListeners();
  }

  // Add setters that call notifyListeners() and persist to storage
  void setFontSize(double value) {
    fontSize = value;
    SettingsService.setFontSize(value);
    notifyListeners();
  }

  void setFontFamily(String family) {
    fontFamily = family;
    SettingsService.setFontFamily(family);
    notifyListeners();
  }

  void setChordColor(Color color) {
    chordColor = color;
    SettingsService.setChordColor(color);
    notifyListeners();
  }

  void setColumnCount(int count) {
    columnCount = count;
    SettingsService.setColumnCount(count);
    notifyListeners();
  }

  void toggleChords() {
    showChords = !showChords;
    SettingsService.setShowChords(showChords);
    notifyListeners();
  }

  void toggleLyrics() {
    showLyrics = !showLyrics;
    SettingsService.setShowLyrics(showLyrics);
    notifyListeners();
  }

  void toggleNotes() {
    showAnnotations = !showAnnotations;
    SettingsService.setShowNotes(showAnnotations);
    notifyListeners();
  }

  void toggleTransitions() {
    showTransitions = !showTransitions;
    SettingsService.setShowTransitions(showTransitions);
    notifyListeners();
  }

  void toggleTextSections() {
    showTextSections = !showTextSections;
    SettingsService.setShowTextSections(showTextSections);
    notifyListeners();
  }

  TextStyle get chordTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    color: chordColor,
    fontWeight: FontWeight.bold,
    height: 2,
    letterSpacing: 0,
  );

  TextStyle get lyricTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    height: 2,
    letterSpacing: 0,
  );
}
