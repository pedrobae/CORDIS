import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/services/firestore_service.dart';

class CloudUserRepository {
  final FirestoreService _firestoreService = FirestoreService();

  CloudUserRepository();

  // ===== CREATE =====
  /// User document is created/updated when user signs in via a CloudFunction

  // ===== READ =====
  /// Fetches a user by their Firebase ID from Firestore
  Future<List<UserDto>> fetchUsersByIds(List<String> userIds) async {
    List<UserDto> users = [];
    for (var userId in userIds) {
      final docSnapshot = await _firestoreService.fetchDocumentById(
        collectionPath: 'users',
        documentId: userId,
      );
      if (docSnapshot != null) {
        users.add(
          UserDto.fromFirestore(
            docSnapshot.data() as Map<String, dynamic>,
            docSnapshot.id,
          ),
        );
      }
    }
    return users;
  }

  Future<UserDto?> fetchUserByEmail(String email) async {
    final querySnapshot = await _firestoreService.fetchDocumentsContainingValue(
      collectionPath: 'users',
      field: 'mail',
      value: email,
      orderField: '',
    );

    if (querySnapshot.isNotEmpty) {
      final doc = querySnapshot.first;
      return UserDto.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ===== UPDATE =====

  // ===== DELETE =====
  /// Deletes the user document from Firestore
  Future<void> deleteUserById(String userId) async {
    await _firestoreService.deleteDocument(
      collectionPath: 'users',
      documentId: userId,
    );
  }
}
