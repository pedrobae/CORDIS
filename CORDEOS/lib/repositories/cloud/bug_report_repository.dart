import 'package:cordeos/helpers/guard.dart';
import 'package:cordeos/models/domain/bug_report.dart';
import 'package:cordeos/services/firebase/firestore_service.dart';
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
