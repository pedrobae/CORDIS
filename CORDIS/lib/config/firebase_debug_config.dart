/// Firebase debug configuration - stores local development secrets
/// This file should be added to .gitignore to prevent committing secrets
class FirebaseDebugConfig {
  /// Get your debug token from Firebase Console:
  /// 1. Go to Project Settings → App Check
  /// 2. Enable "Firebase App Check"
  /// 3. Click on your Android app and enable Debug Provider
  /// 4. Copy the debug token shown
  static const String androidDebugToken =
      'E5EE1CC3-D52B-4F6C-8F78-25CD83B51AA2';

  /// Optional: iOS debug token (usually generated automatically by iOS)
  static const String iosDebugToken = 'D58975CC-3665-4BEE-B72A-FC6D753A5296';
}
