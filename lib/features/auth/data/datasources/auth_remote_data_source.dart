import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<fb.User?> get authStateChanges;
  Future<UserModel?> getCurrentUserData(String uid);
  Future<bool> checkHandleAvailable(String handle);
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  });
  Future<UserModel> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<bool> checkHandleAvailable(String handle) async {
    final cleanHandle = handle.toLowerCase().trim();
    if (!AppConstants.handleRegex.hasMatch(cleanHandle)) {
      throw const InvalidHandleFailure();
    }
    final docRef = _firestore.collection(AppConstants.handlesCollection).doc(cleanHandle);
    final docSnap = await docRef.get();
    return !docSnap.exists;
  }

  @override
  Future<UserModel> getCurrentUserData(String uid) async {
    final docSnap = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!docSnap.exists) {
      throw const ServerFailure('User profile not found in database.');
    }
    return UserModel.fromFirestore(docSnap);
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String handle,
    required String displayName,
  }) async {
    final cleanHandle = handle.toLowerCase().trim();
    if (!AppConstants.handleRegex.hasMatch(cleanHandle)) {
      throw const InvalidHandleFailure();
    }

    final handleDocRef = _firestore.collection(AppConstants.handlesCollection).doc(cleanHandle);

    // 1. Create Firebase Auth user
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('Failed to register user.');
    }

    final userModel = UserModel(
      uid: user.uid,
      email: email.trim(),
      handle: cleanHandle,
      displayName: displayName.trim(),
      bio: '',
      createdAt: DateTime.now(),
    );

    // 2. Perform Atomic Firestore Transaction to claim handle & create user doc
    try {
      await _firestore.runTransaction((transaction) async {
        final handleSnap = await transaction.get(handleDocRef);
        if (handleSnap.exists) {
          throw const HandleAlreadyTakenFailure();
        }

        // Claim handle
        transaction.set(handleDocRef, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Write user document
        final userDocRef = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
        transaction.set(userDocRef, userModel.toFirestore());
      });

      // Update Auth Display Name
      await user.updateDisplayName(displayName.trim());
      return userModel;
    } catch (e) {
      // If transaction fails (e.g. handle taken), clean up created auth user to avoid orphan auth state
      if (e is HandleAlreadyTakenFailure) {
        await user.delete();
        rethrow;
      }
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('Failed to sign in.');
    }

    return await getCurrentUserData(user.uid);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
