import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        return await _remoteDataSource.getCurrentUserData(fbUser.uid);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final currentFbUser = fb.FirebaseAuth.instance.currentUser;
    if (currentFbUser == null) return null;
    return await _remoteDataSource.getCurrentUserData(currentFbUser.uid);
  }

  @override
  Future<bool> isHandleAvailable(String handle) {
    return _remoteDataSource.checkHandleAvailable(handle);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      handle: handle,
      displayName: displayName,
    );
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
