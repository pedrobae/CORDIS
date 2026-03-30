import 'package:cordeos/models/dtos/user_dto.dart';
import 'package:cordeos/services/firebase/firestore_service.dart';

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
    final querySnapshot = await _firestoreService.fetchDocumentByField(
      collectionPath: 'users',
      fieldName: 'email',
      fieldValue: email,
    );

    if (querySnapshot == null) return null;
    return UserDto.fromFirestore(querySnapshot.data() as Map<String, dynamic>);
  }

  // ===== UPDATE =====
  /// Updates the user's data in Firestore.
  Future<void> update(UserDto userDto) async {
    await _firestoreService.updateDocument(
      collectionPath: 'users',
      documentId: userDto.firebaseId!,
      data: userDto.toFirestore(),
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
