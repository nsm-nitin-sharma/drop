import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of current authenticated user state
  Stream<UserEntity?> get authStateChanges;

  /// Get current user profile
  Future<UserEntity?> getCurrentUser();

  /// Register user with Email/Password & Atomic `@handle` reservation
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  });

  /// Login with Email or Handle (@username) and Password
  Future<UserEntity> signInWithEmailOrHandle({
    required String loginInput,
    required String password,
  });

  /// Check if a handle (@username) is available in Firestore
  Future<bool> isHandleAvailable(String handle);

  /// Sign Out
  Future<void> signOut();
}
