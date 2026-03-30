// utils/string_utils.dart
class StringUtils {
  static int stringToHash(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.codeUnitAt(i);
    }
    return hash.abs();
  }

  static String capitalize(String text) {
    return text.isNotEmpty
        ? '${text[0].toUpperCase()}${text.substring(1)}'
        : '';
  }

  static String toTitleCase(String text) {
    return text.split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }
}