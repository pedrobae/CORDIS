import 'package:cordis/helpers/guard.dart';
import 'package:cordis/models/domain/bug_report.dart';
import 'package:cordis/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

class BugReportRepository {
  final FirestoreService _firestore = FirestoreService();
  final GuardHelper _guard = GuardHelper();

  // ===== CREATE =====
  Future<String?> reportBug(BugReport bugReport) async {
    try {
      _guard.requireAuth();

      final id = await _firestore.createDocument(
        collectionPath: 'bug_reports',
        data: bugReport.toFirestore(),
      );
      return id;
    } catch (e) {
      debugPrint('Error reporting bug: $e');
      rethrow;
    }
  }
}
