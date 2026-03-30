import 'package:cordeos/models/domain/bug_report.dart';
import 'package:cordeos/repositories/cloud/bug_report_repository.dart';
import 'package:flutter/material.dart';

class BugReportProvider extends ChangeNotifier {
  final _repo = BugReportRepository();

  bool _isReporting = false;
  String? _error;

  bool get isReporting => _isReporting;
  String? get error => _error;

  // Returns whether the report was successfully submitted.
  // Note that this does not guarantee that the report was actually received by the backend
  // Only that the submission process completed without throwing an error.
  Future<bool> reportBug(BugReport report) async {
    bool success = false;
    _isReporting = true;
    notifyListeners();

    try {
      final id = await _repo.reportBug(report);

      if (id is String) success = true;
    } catch (e) {
      _error = e.toString();
      print('Error reporting bug: $e');
    } finally {
      _isReporting = false;
      notifyListeners();
    }
    return success;
  }
}
