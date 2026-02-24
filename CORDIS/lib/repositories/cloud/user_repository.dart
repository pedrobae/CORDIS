import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/services/firestore_service.dart';

class CloudUserRepository {
  final FirestoreService _firestoreService = FirestoreService();

  CloudUserRepository();

  // ===== CREATE =====
  /// User document is created/updated when user signs in via a CloudFunction

  // ===== READ =====
  /// Fetches a user by their Firebase ID from Firestore
  Future<UserDto?> fetchUserById(String userId) async {
    final docSnapshot = await _firestoreService.fetchDocumentById(
      collectionPath: 'users',
      documentId: userId,
    );
    if (docSnapshot != null) {
      return UserDto.fromFirestore(docSnapshot.data() as Map<String, dynamic>);
    }
    return null;
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
      return UserDto.fromFirestore(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // ===== UPDATE =====
  /// Updates the user's data in Firestore. Only fields provided in the [data] map will be updated.
  Future<void> update(String userId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(
      collectionPath: 'users',
      documentId: userId,
      data: data,
    );
  }

  // ===== DELETE =====
  /// Deletes the user document from Firestore
  Future<void> deleteUserById(String userId) async {
    await _firestoreService.deleteDocument(
      collectionPath: 'users',
      documentId: userId,
    );
  }
}
