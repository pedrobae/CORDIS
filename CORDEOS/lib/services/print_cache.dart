import 'package:shared_preferences/shared_preferences.dart';

class PrintCacheService {
  // Style Settings Keys
  static const String _keyLyricFontSize = 'print_lyric_font_size';
  static const String _keyLyricFontFamily = 'print_lyric_font_family';
  static const String _keyChordFontSize = 'chord_font_size';
  static const String _keyChordFontFamily = 'chord_font_family';
  static const String _keyHeaderFontSize = 'header_font_size';
  static const String _keyHeaderFontFamily = 'header_font_family';

  // Layout Settings Keys
  static const String _keyLineSpacing = 'print_line_spacing';
  static const String _keyLineBreakSpacing = 'print_line_break_spacing';
  static const String _keyChordLyricSpacing = 'print_chord_lyric_spacing';
  static const String _keyMinChordSpacing = 'print_min_chord_spacing';
  static const String _keyLetterSpacing = 'print_letter_spacing';

  // Filter Settings Keys
  static const String _keyShowHeader = 'print_show_header';
  static const String _keyShowSongMap = 'print_show_map';
  static const String _keyShowBpm = 'print_show_bpm';
  static const String _keyShowDuration = 'print_show_duration';

  static const String _keyShowAnnotations = 'print_show_annotations';
  static const String _keyShowRepeatSections = 'print_show_repeat_sections';

  static const String _keyShowLabel = 'print_show_labels';

  // Page Layout Settings Keys
  static const String _keyHorizontalMargin = 'print_horizontal_margin';
  static const String _keyVertical = 'print_vertical_margin';
  static const String _keySectionSpacing = 'print_section_spacing';
  static const String _keyHeaderGap = 'print_header_gap';
  static const String _keyColumnGap = 'print_column_gap';
  static const String _keyColumnCount = 'print_column_count';

  static SharedPreferences? _prefs;

  /// Initialize the service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get _preferences {
    assert(_prefs != null, 'SettingsService must be initialized first');
    return _prefs!;
  }

  // =========== LAYOUT SETTINGS =============

  static Future<void> setLyricSize(double size) async {
    await _preferences.setDouble(_keyLyricFontSize, size);
  }

  static double getLyricSize() {
    return _preferences.getDouble(_keyLyricFontSize) ?? 12.0;
  }

  static Future<void> setLyricFontFamily(String family) async {
    await _preferences.setString(_keyLyricFontFamily, family);
  }

  static String getLyricFontFamily() {
    return _preferences.getString(_keyLyricFontFamily) ?? 'OpenSans';
  }

  static Future<void> setChordSize(double size) async {
    await _preferences.setDouble(_keyChordFontSize, size);
  }

  static double getChordSize() {
    return _preferences.getDouble(_keyChordFontSize) ?? 10.0;
  }

  static Future<void> setChordFontFamily(String family) async {
    await _preferences.setString(_keyChordFontFamily, family);
  }

  static String getChordFontFamily() {
    return _preferences.getString(_keyChordFontFamily) ?? 'OpenSans';
  }

  static Future<void> setHeaderSize(double size) async {
    await _preferences.setDouble(_keyHeaderFontSize, size);
  }

  static double getHeaderSize() {
    return _preferences.getDouble(_keyHeaderFontSize) ?? 12.0;
  }

  static Future<void> setHeaderFontFamily(String family) async {
    await _preferences.setString(_keyHeaderFontFamily, family);
  }

  static String getHeaderFontFamily() {
    return _preferences.getString(_keyHeaderFontFamily) ?? 'OpenSans';
  }

  static Future<void> setLineSpacing(double spacing) async {
    await _preferences.setDouble(_keyLineSpacing, spacing);
  }

  static double getLineSpacing() {
    return _preferences.getDouble(_keyLineSpacing) ?? 2;
  }

  static Future<void> setLineBreakSpacing(double spacing) async {
    await _preferences.setDouble(_keyLineBreakSpacing, spacing);
  }

  static double getLineBreakSpacing() {
    return _preferences.getDouble(_keyLineBreakSpacing) ?? 0;
  }

  static Future<void> setChordLyricSpacing(double spacing) async {
    await _preferences.setDouble(_keyChordLyricSpacing, spacing);
  }

  static double getChordLyricSpacing() {
    return _preferences.getDouble(_keyChordLyricSpacing) ?? 0.0;
  }

  static Future<void> setMinChordSpacing(double spacing) async {
    await _preferences.setDouble(_keyMinChordSpacing, spacing);
  }

  static double getMinChordSpacing() {
    return _preferences.getDouble(_keyMinChordSpacing) ?? 4.0;
  }

  static Future<void> setLetterSpacing(double spacing) async {
    await _preferences.setDouble(_keyLetterSpacing, spacing);
  }

  static double getLetterSpacing() {
    return _preferences.getDouble(_keyLetterSpacing) ?? 0.0;
  }

  // =========== FILTER SETTINGS =============

  static Future<void> setShowHeader(bool show) async {
    await _preferences.setBool(_keyShowHeader, show);
  }

  static bool getShowHeader() {
    return _preferences.getBool(_keyShowHeader) ?? true;
  }

  static Future<void> setShowSongMap(bool show) async {
    await _preferences.setBool(_keyShowSongMap, show);
  }

  static bool getShowSongMap() {
    return _preferences.getBool(_keyShowSongMap) ?? true;
  }

  static Future<void> setShowBpm(bool show) async {
    await _preferences.setBool(_keyShowBpm, show);
  }

  static bool getShowBpm() {
    return _preferences.getBool(_keyShowBpm) ?? true;
  }

  static Future<void> setShowDuration(bool show) async {
    await _preferences.setBool(_keyShowDuration, show);
  }

  static bool getShowDuration() {
    return _preferences.getBool(_keyShowDuration) ?? true;
  }

  static Future<void> setShowAnnotations(bool show) async {
    await _preferences.setBool(_keyShowAnnotations, show);
  }

  static bool getShowAnnotations() {
    return _preferences.getBool(_keyShowAnnotations) ?? true;
  }

  static Future<void> setShowRepeatSections(bool show) async {
    await _preferences.setBool(_keyShowRepeatSections, show);
  }

  static bool getShowRepeatSections() {
    return _preferences.getBool(_keyShowRepeatSections) ?? true;
  }

  static Future<void> setShowLabel(bool show) async {
    await _preferences.setBool(_keyShowLabel, show);
  }

  static bool getShowLabel() {
    return _preferences.getBool(_keyShowLabel) ?? true;
  }

  // =========== PAGE LAYOUT SETTINGS =============

  static Future<void> setHorizontalMargin(double margin) async {
    await _preferences.setDouble(_keyHorizontalMargin, margin);
  }

  static double getHorizontalMargin() {
    return _preferences.getDouble(_keyHorizontalMargin) ?? 24.0;
  }

  static Future<void> setVerticalMargin(double margin) async {
    await _preferences.setDouble(_keyVertical, margin);
  }

  static double getVerticalMargin() {
    return _preferences.getDouble(_keyVertical) ?? 24.0;
  }

  static Future<void> setSectionSpacing(double spacing) async {
    await _preferences.setDouble(_keySectionSpacing, spacing);
  }

  static double getSectionSpacing() {
    return _preferences.getDouble(_keySectionSpacing) ?? 16.0;
  }

  static Future<void> setHeaderGap(double gap) async {
    await _preferences.setDouble(_keyHeaderGap, gap);
  }

  static double getHeaderGap() {
    return _preferences.getDouble(_keyHeaderGap) ?? 12.0;
  }

  static Future<void> setColumnGap(double gap) async {
    await _preferences.setDouble(_keyColumnGap, gap);
  }

  static double getColumnGap() {
    return _preferences.getDouble(_keyColumnGap) ?? 16.0;
  }

  static Future<void> setColumnCount(int count) async {
    await _preferences.setInt(_keyColumnCount, count);
  }

  static int getColumnCount() {
    return _preferences.getInt(_keyColumnCount) ?? 1;
  }
}
