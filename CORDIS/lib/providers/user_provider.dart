import 'dart:async';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/repositories/local_user_repository.dart';
import 'package:cordis/repositories/cloud_user_repository.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _localUserRepository = UserRepository();
  final CloudUserRepository _cloudUserRepository = CloudUserRepository();

  UserProvider();

  List<User> _knownUsers = [];
  String? _error;
  bool _hasInitialized = false;
  bool _isLoading = false;
  bool _isLoadingCloud = false;

  // Getters
  List<User> get knownUsers => _knownUsers;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;
  bool get isLoading => _isLoading;
  bool get isLoadingCloud => _isLoadingCloud;

  // ===== CREATE =====
  /// Downloads users from Firebase
  /// Saves them to local SQLite db
  Future<void> downloadUsersFromCloud(List<String> firebaseUserIds) async {
    if (_isLoadingCloud) return;

    _isLoadingCloud = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _cloudUserRepository.fetchUsersByIds(firebaseUserIds);

      for (final userDto in users) {
        final user = userDto.toDomain();
        final userId = await _localUserRepository.createUser(user);
        _knownUsers.add(user.copyWith(id: userId));

        if (kDebugMode) {
          print('Downloaded and saved user: ${user.username}');
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error downloading users from cloud: $e');
      }
    } finally {
      _isLoadingCloud = false;
      notifyListeners();
    }
  }

  /// Ensures that all users in the provided list of Firebase IDs exist locally
  /// Downloads any missing users from the cloud
  Future<void> ensureUsersExist(List<String> firebaseUserIds) async {
    final presentIds = await _localUserRepository.getUsersByFirebaseId(
      firebaseUserIds,
    );

    final missingIds = firebaseUserIds
        .where((id) => !presentIds.contains(id))
        .toList();

    if (missingIds.isNotEmpty) {
      await downloadUsersFromCloud(missingIds);
    }
  }

  Future<User> createLocalUnknownUser(String username, String email) async {
    final newUser = User(
      id: -1,
      username: username,
      mail: email,
      firebaseId: null,
    );

    final userId = await _localUserRepository.createUser(newUser);
    final savedUser = newUser.copyWith(id: userId);
    _knownUsers.add(savedUser);
    notifyListeners();
    return savedUser;
  }

  // ==== READ =====
  /// Load users from local SQLite db
  Future<void> loadUsers() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _knownUsers = await _localUserRepository.getAllUsers();
      _hasInitialized = true;

      if (kDebugMode) {
        print('Loaded ${_knownUsers.length} Users from SQLite');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading ciphers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///
  Future<UserDto?> fetchUserDtoByEmail(String email) async {
    if (_isLoading) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    UserDto? userDto;

    try {
      userDto = await _cloudUserRepository.fetchUserByEmail(email);
    } catch (e) {
      if (kDebugMode) {
        print('User with Email $email not found on firestore.');
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return userDto;
  }

  int? getLocalIdByFirebaseId(String firebaseId) {
    try {
      final user = _knownUsers.firstWhere(
        (user) => user.firebaseId == firebaseId,
      );
      return user.id;
    } catch (e) {
      if (kDebugMode) {
        print('User with Firebase ID $firebaseId not found locally.');
      }
      throw Exception('User with Firebase ID $firebaseId not found locally.');
    }
  }

  String getFirebaseIdByLocalId(int localId) {
    try {
      final user = _knownUsers.firstWhere((user) => user.id == localId);
      return user.firebaseId!;
    } catch (e) {
      if (kDebugMode) {
        print('User with local ID $localId not found locally.');
      }
      throw Exception('User with local ID $localId not found locally.');
    }
  }

  List<User> getUsersByIds(List<int> ids) {
    return _knownUsers.where((user) => ids.contains(user.id)).toList();
  }

  List<User> getUsersByFirebaseIds(List<String> firebaseIds) {
    return _knownUsers
        .where((user) => firebaseIds.contains(user.firebaseId))
        .toList();
  }

  void clearCache() {
    _knownUsers = [];
    _error = null;
    _hasInitialized = false;
    _isLoading = false;
    _isLoadingCloud = false;
    notifyListeners();
  }
}
