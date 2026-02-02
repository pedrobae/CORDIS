import 'package:flutter/foundation.dart';

class EmailProvider extends ChangeNotifier {
  // State management
  String? _error;

  String? get error => _error;

  /// Sends invitation emails for the given schedule to users with the selected roles.
  /// Returns true if emails were sent successfully, false otherwise.
  Future<bool> sendInvites(dynamic schedule, List<String> selectedRoles) async {
    try {
      throw UnimplementedError();
      // TODO - EMAIL SENDING LOGIC HERE
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
