import 'package:flutter/foundation.dart';

final class BuildTrace {
  BuildTrace._();

  static final Map<String, int> _buildCounts = <String, int>{};

  static void rebuild(String scope, {String? details}) {
    assert(() {
      final nextCount = (_buildCounts[scope] ?? 0) + 1;
      _buildCounts[scope] = nextCount;

      final suffix = details == null || details.isEmpty ? '' : ' | $details';
      debugPrint('[BuildTrace] $scope build #$nextCount$suffix');
      return true;
    }());
  }

  static void event(String scope, String message) {
    assert(() {
      debugPrint('[BuildTrace] $scope | $message');
      return true;
    }());
  }

  static void reset({String? prefix}) {
    assert(() {
      if (prefix == null || prefix.isEmpty) {
        _buildCounts.clear();
      } else {
        _buildCounts.removeWhere((key, _) => key.startsWith(prefix));
      }

      return true;
    }());
  }
}