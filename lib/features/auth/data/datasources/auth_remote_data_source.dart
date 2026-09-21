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
    required String loginInput,
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
      return false;
    }
    try {
      final docRef = _firestore.collection(AppConstants.handlesCollection).doc(cleanHandle);
      final docSnap = await docRef.get();
      return !docSnap.exists;
    } catch (_) {
      // Return false gracefully on network issue or restriction
      return false;
    }
  }

  @override
  Future<UserModel> getCurrentUserData(String uid) async {
    try {
      final docSnap = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (!docSnap.exists) {
        throw const ServerFailure('User profile not found.');
      }
      return UserModel.fromFirestore(docSnap);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Unable to load user profile. Please try again.');
    }
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

    fb.UserCredential? credential;
    try {
      // 1. Create Firebase Auth user
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthFailure('This email address is already registered.');
        case 'invalid-email':
          throw const AuthFailure('Please enter a valid email address.');
        case 'weak-password':
          throw const AuthFailure('Password should be at least 6 characters.');
        default:
          throw const AuthFailure('Could not complete registration. Please check your details.');
      }
    } catch (e) {
      throw const AuthFailure('Registration failed. Please try again.');
    }

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

        transaction.set(handleDocRef, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final userDocRef = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
        transaction.set(userDocRef, userModel.toFirestore());
      });

      await user.updateDisplayName(displayName.trim());
      return userModel;
    } catch (e) {
      if (e is HandleAlreadyTakenFailure) {
        await user.delete();
        rethrow;
      }
      await user.delete();
      throw const AuthFailure('Unable to save user profile. Please try again.');
    }
  }

  @override
  Future<UserModel> signIn({
    required String loginInput,
    required String password,
  }) async {
    final rawInput = loginInput.trim().toLowerCase();
    String emailToUse = rawInput;

    // Check if user entered a handle instead of an email (e.g. nitin_sharma or @nitin_sharma)
    final cleanHandle = rawInput.startsWith('@') ? rawInput.substring(1) : rawInput;

    if (!cleanHandle.contains('@')) {
      // Resolve email from handle document in Firestore
      try {
        final handleDoc = await _firestore.collection(AppConstants.handlesCollection).doc(cleanHandle).get();
        if (!handleDoc.exists) {
          throw const AuthFailure('Incorrect handle or password.');
        }

        final uid = handleDoc.data()?['uid'] as String?;
        if (uid == null) {
          throw const AuthFailure('Incorrect handle or password.');
        }

        final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
        final email = userDoc.data()?['email'] as String?;
        if (email == null || email.isEmpty) {
          throw const AuthFailure('Incorrect handle or password.');
        }

        emailToUse = email;
      } catch (e) {
        if (e is AuthFailure) rethrow;
        throw const AuthFailure('Incorrect handle/email or password.');
      }
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Failed to sign in.');
      }

      return await getCurrentUserData(user.uid);
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthFailure('Incorrect handle/email or password.');
        case 'invalid-email':
          throw const AuthFailure('Please enter a valid handle or email address.');
        case 'user-disabled':
          throw const AuthFailure('This account has been disabled.');
        case 'too-many-requests':
          throw const AuthFailure('Too many failed attempts. Please wait a moment and try again.');
        default:
          throw const AuthFailure('Incorrect handle/email or password.');
      }
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure('Unable to log in. Please check your connection.');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
