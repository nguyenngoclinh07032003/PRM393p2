import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import '../config/app_constants.dart';

import 'local_storage_service.dart';



class AuthService extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final LocalStorageService _storage = LocalStorageService();

  String? _cachedRole;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();



  Future<Map<String, dynamic>?> signIn(String email, String password) async {

    try {

      final normalizedEmail = email.trim().toLowerCase();

      final credential = await _auth.signInWithEmailAndPassword(

        email: normalizedEmail,

        password: password,

      );



      if (credential.user != null) {

        final userData = await _loadUserData(credential.user!, normalizedEmail);

        final role = userData['role'] as String? ?? AppConstants.roleCustomer;

        await _storage.saveUserId(credential.user!.uid);

        await _storage.saveUserRole(role);

        _cachedRole = role;

        await _storage.setLoggedIn(true);

        notifyListeners();

        return userData;

      }

      return null;

    } catch (e) {

      debugPrint('Sign in error: $e');

      rethrow;

    }

  }



  Future<User?> signUp({

    required String email,

    required String password,

    required String name,

    required String phone,

    required String address,

    String role = AppConstants.roleCustomer,

  }) async {

    try {

      final normalizedEmail = email.trim().toLowerCase();

      final resolvedRole = _isDesignatedAdmin(normalizedEmail)

          ? AppConstants.roleAdmin

          : AppConstants.roleCustomer;



      final credential = await _auth.createUserWithEmailAndPassword(

        email: normalizedEmail,

        password: password,

      );



      if (credential.user != null) {

        await _firestore

            .collection(AppConstants.usersCollection)

            .doc(credential.user!.uid)

            .set({

          'uid': credential.user!.uid,

          'email': normalizedEmail,

          'fullName': name,

          'phone': phone,

          'address': address,

          'role': resolvedRole,

          'status': AppConstants.statusActive,

          'createdAt': FieldValue.serverTimestamp(),

        });



        await _storage.saveUserId(credential.user!.uid);

        await _storage.saveUserRole(resolvedRole);

        _cachedRole = resolvedRole;

        await _storage.setLoggedIn(true);

        notifyListeners();

        return credential.user;

      }

      return null;

    } catch (e) {

      debugPrint('Sign up error: $e');

      rethrow;

    }

  }



  Future<void> signOut() async {

    try {

      await _auth.signOut();

      await _storage.clear();

      _cachedRole = null;

      notifyListeners();

    } catch (e) {

      debugPrint('Sign out error: $e');

      rethrow;

    }

  }



  Future<String?> getUserRole({bool forceRefresh = false}) async {

    try {

      if (currentUser == null) return null;

      if (!forceRefresh && _cachedRole != null) {

        return _cachedRole;

      }



      final email = currentUser!.email?.trim().toLowerCase() ?? '';

      if (_isDesignatedAdmin(email)) {

        await _promoteToAdmin(currentUser!.uid, email);

        _cachedRole = AppConstants.roleAdmin;

        return _cachedRole;

      }



      final userDoc = await _firestore

          .collection(AppConstants.usersCollection)

          .doc(currentUser!.uid)

          .get();



      if (userDoc.exists) {
        final data = userDoc.data();
        final status = data?['status'] as String? ?? AppConstants.statusActive;
        if (status == AppConstants.statusInactive) {
          return null;
        }
        _cachedRole = data?['role'] as String?;

        return _cachedRole;

      }

      _cachedRole = AppConstants.roleCustomer;

      return _cachedRole;

    } catch (e) {

      debugPrint('Get user role error: $e');

      return _cachedRole;

    }

  }



  Future<Map<String, dynamic>?> getUserProfile() async {

    try {

      if (currentUser == null) return null;



      final userDoc = await _firestore

          .collection(AppConstants.usersCollection)

          .doc(currentUser!.uid)

          .get();



      if (userDoc.exists) {

        return userDoc.data();

      }

      return null;

    } catch (e) {

      debugPrint('Get user profile error: $e');

      return null;

    }

  }



  Future<void> updateDeliveryProfile({

    required String fullName,

    required String phone,

    required String address,

  }) async {

    if (currentUser == null) return;



    await _firestore

        .collection(AppConstants.usersCollection)

        .doc(currentUser!.uid)

        .set({

      'fullName': fullName,

      'phone': phone,

      'address': address,

    }, SetOptions(merge: true));

  }



  Future<void> resetPassword(String email) async {

    try {

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

    } catch (e) {

      debugPrint('Reset password error: $e');

      rethrow;

    }

  }



  Future<Map<String, dynamic>> _loadUserData(User user, String email) async {

    final normalizedEmail = email.trim().toLowerCase();



    if (_isDesignatedAdmin(normalizedEmail)) {

      await _promoteToAdmin(user.uid, normalizedEmail);

    }



    try {

      final userDoc = await _firestore

          .collection(AppConstants.usersCollection)

          .doc(user.uid)

          .get();



      if (userDoc.exists) {

        final data = Map<String, dynamic>.from(userDoc.data()!);

        if (_isDesignatedAdmin(normalizedEmail)) {

          data['role'] = AppConstants.roleAdmin;

        }

        return data;

      }

    } catch (e) {

      debugPrint('Load user profile warning: $e');

    }



    final role = _isDesignatedAdmin(normalizedEmail)

        ? AppConstants.roleAdmin

        : AppConstants.roleCustomer;

    return _fallbackUserData(user, normalizedEmail, role);

  }



  bool _isDesignatedAdmin(String email) {

    final normalized = email.trim().toLowerCase();

    return AppConstants.designatedAdminEmails

        .map((e) => e.trim().toLowerCase())

        .contains(normalized);

  }



  Future<void> _promoteToAdmin(String uid, String email) async {

    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({

      'uid': uid,

      'email': email.trim().toLowerCase(),

      'role': AppConstants.roleAdmin,

      'status': AppConstants.statusActive,

    }, SetOptions(merge: true));

  }



  Map<String, dynamic> _fallbackUserData(User user, String email, String role) {

    return {

      'uid': user.uid,

      'email': email,

      'fullName': user.displayName ?? 'SmartDeal User',

      'phone': '',

      'address': '',

      'role': role,

      'status': AppConstants.statusActive,

    };

  }

}


