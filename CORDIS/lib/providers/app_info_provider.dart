import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider extends ChangeNotifier {
  String _appVersion = 'Unknown';
  bool _isLoading = false;

  String get appVersion => _appVersion;
  bool get isLoading => _isLoading;

  AppInfoProvider() {
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    _isLoading = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      _appVersion = 'Unknown';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
