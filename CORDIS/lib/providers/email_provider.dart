import 'package:cloud_functions/cloud_functions.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:flutter/foundation.dart';

class EmailProvider extends ChangeNotifier {
  // State management
  String? _error;
  bool _isSending = false;

  String? get error => _error;
  bool get isSending => _isSending;

  /// Sends invitation emails for the given schedule to users with the selected roles.
  /// Returns true if emails were sent successfully, false otherwise.
  Future<bool> sendInvites(
    Schedule schedule,
    List<String> selectedRoles,
  ) async {
    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      final functions = FirebaseFunctions.instance;
      final sendInviteEmail = functions.httpsCallable('sendInviteEmail');

      int successCount = 0;
      int failureCount = 0;

      for (var role in schedule.roles) {
        if (selectedRoles.contains(role.name)) {
          for (var user in role.users) {
            try {
              await sendInviteEmail.call({
                'email': user.email,
                'userName': user.username,
                'roleName': role.name,
                'scheduleTitle': schedule.name,
              });
              successCount++;
              debugPrint(
                'Invitation sent to ${user.email} for role ${role.name}',
              );
            } catch (e) {
              failureCount++;
              debugPrint('Failed to send email to ${user.email}: $e');
            }
          }
        }
      }

      _isSending = false;

      if (failureCount > 0) {
        _error =
            'Failed to send $failureCount invitation(s). Sent $successCount successfully.';
      }

      notifyListeners();
      return failureCount == 0;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      debugPrint('Error in sendInvites: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
