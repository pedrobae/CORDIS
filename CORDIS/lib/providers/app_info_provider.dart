import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider extends ChangeNotifier {
  PackageInfo? _packageInfo;
  bool _isLoading = false;

  String get appVersion => _packageInfo?.version ?? 'Unknown';
  bool get isLoading => _isLoading;

  AppInfoProvider() {
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    _isLoading = true;
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _packageInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
