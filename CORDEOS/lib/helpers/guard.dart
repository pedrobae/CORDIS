import 'package:cordeos/services/firebase/auth_service.dart';

class GuardHelper {
  final AuthService _authService = AuthService();
  CipherPublishGuard cipherPublishGuard;

  GuardHelper({this.cipherPublishGuard = CipherPublishGuard.adminOnly});

  // ===== PERMISSION HELPERS =====
  Future<void> requireAdmin() async {
    if (!(await _authService.isAdmin)) {
      throw Exception(
        'Acesso negado: operação requer privilégios de administrador',
      );
    }
  }

  Future<void> requireAuth() async {
    if (!_authService.isAuthenticated) {
      throw Exception('Acesso negado: usuário deve estar autenticado');
    }
  }

  Future<void> ensureCanPublishCiphers() async {
    await requireAuth();
    switch (cipherPublishGuard) {
      case CipherPublishGuard.adminOnly:
        await requireAdmin();
        return;
      case CipherPublishGuard.everyone:
        // Could add additional checks here (e.g., account age, reputation)
        return;
    }
  }

  /// CHECKS IF CURRENT USER IS THE OWNER OF THE RESOURCE
  Future<void> requireOwnership(String resourceOwnerId) async {
    await requireAuth();
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.uid != resourceOwnerId) {
      throw Exception('Acesso negado: usuário não é o proprietário');
    }
  }
}

enum CipherPublishGuard { adminOnly, everyone }
