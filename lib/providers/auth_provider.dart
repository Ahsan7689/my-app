import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isInitialized = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _user != null && _userModel != null;
  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('🔄 Initializing auth...');

    // Check if user is already signed in
    _user = _auth.currentUser;

    if (_user != null) {
      print('✅ Found existing user: ${_user!.email}');
      await _loadUserData(_user!.uid);
    }

    _isInitialized = true;
    notifyListeners();

    // Listen to auth changes
    _auth.authStateChanges().listen((User? user) async {
      print('🔄 Auth state changed: ${user?.email ?? "null"}');
      _user = user;

      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userModel = null;
      }

      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      print('📥 Loading user data for: $uid');

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        print('✅ User document found');
        final data = doc.data() as Map<String, dynamic>;
        _userModel = UserModel.fromMap(data);
        print('✅ User loaded: ${_userModel!.name}, isAdmin: ${_userModel!.isAdmin}');
      } else {
        print('❌ User document NOT found');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      print('🔐 Signing in with email...');

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      print('✅ Authentication successful');

      if (_user != null) {
        await _loadUserData(_user!.uid);

        if (_userModel == null) {
          print('❌ User profile not found');
          await _auth.signOut();
          return false;
        }

        print('✅ Sign in complete');
        return true;
      }

      return false;

    } on FirebaseAuthException catch (e) {
      print('❌ Auth error: ${e.code}');
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    User? tempUser;

    try {
      print('📝 Starting signup...');

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      tempUser = credential.user;

      if (tempUser == null) {
        print('❌ Auth user creation failed');
        return false;
      }

      print('✅ Auth user created: ${tempUser.uid}');

      final newUser = UserModel(
        uid: tempUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        isAdmin: false,
      );

      print('⏳ Saving to Firestore...');

      await _firestore
          .collection('users')
          .doc(tempUser.uid)
          .set(newUser.toMap());

      print('✅ User document saved');

      await Future.delayed(Duration(milliseconds: 500));

      DocumentSnapshot verifyDoc = await _firestore
          .collection('users')
          .doc(tempUser.uid)
          .get();

      if (!verifyDoc.exists) {
        print('❌ Verification failed');
        await tempUser.delete();
        return false;
      }

      developer.log('✅ Document verified', name: 'my_app.auth_provider');

      _user = tempUser;
      _userModel = newUser;
      notifyListeners();

      developer.log('🎉 Signup completed!', name: 'my_app.auth_provider');
      return true;

    } catch (e, s) {
      developer.log('❌ Signup error', name: 'my_app.auth_provider', error: e, stackTrace: s);

      if (tempUser != null) {
        try {
          await tempUser.delete();
        } catch (e, s) {
          developer.log('⚠️ Cleanup failed', name: 'my_app.auth_provider', error: e, stackTrace: s);
        }
      }

      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      developer.log('🔐 Starting Google sign in...', name: 'my_app.auth_provider');

      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('❌ User cancelled', name: 'my_app.auth_provider');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user == null) {
        developer.log('❌ Firebase sign in failed', name: 'my_app.auth_provider');
        return false;
      }

      developer.log('✅ Firebase auth successful', name: 'my_app.auth_provider');

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (!doc.exists) {
        final newUser = UserModel(
          uid: _user!.uid,
          email: _user!.email!,
          name: _user!.displayName ?? 'User',
          createdAt: DateTime.now(),
          isAdmin: false,
        );

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(newUser.toMap());

        _userModel = newUser;
      } else {
        final data = doc.data() as Map<String, dynamic>;
        _userModel = UserModel.fromMap(data);
      }

      notifyListeners();
      developer.log('🎉 Google sign in completed!', name: 'my_app.auth_provider');
      return true;

    } catch (e, s) {
      developer.log('❌ Google sign in error', name: 'my_app.auth_provider', error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> signOut() async {
    developer.log('👋 Signing out...', name: 'my_app.auth_provider');
    await _auth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
    developer.log('✅ Signed out', name: 'my_app.auth_provider');
  }

  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
  }) async {
    try {
      if (_user == null) return false;

      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (postalCode != null) updates['postalCode'] = postalCode;

      await _firestore.collection('users').doc(_user!.uid).update(updates);
      await _loadUserData(_user!.uid);
      return true;
    } catch (e, s) {
      developer.log('❌ Update error', name: 'my_app.auth_provider', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e, s) {
      developer.log('❌ Reset error', name: 'my_app.auth_provider', error: e, stackTrace: s);
      return false;
    }
  }
}
