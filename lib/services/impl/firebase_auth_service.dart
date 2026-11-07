import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user.dart';
import '../auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  FirebaseAuthService() {
    // Emit initial state immediately
    _emitCurrentUserState();
    
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _controller.add(null);
      } else {
        // Always load user with role from Firestore
        _loadAndEmitUserWithRole(user.uid);
      }
    });
  }

  Future<void> _emitCurrentUserState() async {
    final user = _auth.currentUser;
    if (user == null) {
      _controller.add(null);
    } else {
      await _loadAndEmitUserWithRole(user.uid);
    }
  }

  Future<void> _loadAndEmitUserWithRole(String uid) async {
    try {
      print('Loading user with role for UID: $uid');
      final userWithRole = await getUserWithRole(uid);
      print('User with role loaded: ${userWithRole?.role}');
      _cachedUser = userWithRole;
      _controller.add(userWithRole);
    } catch (e) {
      print('Error loading user role: $e');
      // If loading fails, emit null to trigger login
      _cachedUser = null;
      _controller.add(null);
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return (() async* {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          yield null;
        } else {
          yield await getUserWithRole(user.uid);
        }
      } catch (e) {
        // If we fail to load, emit null so callers can redirect to login.
        yield null;
      }

      yield* _controller.stream;
    })().asBroadcastStream();
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;

    final cached = _cachedUser;
    if (cached != null && cached.id == user.uid) {
      return cached;
    }

    return AppUser(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      role: UserRole.student,
      handlerRole: null,
      canteen: null,
    );
  }

  @override
  Future<AppUser?> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      // Verify user role matches
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      if (userData['role'] != role.name) {
        await _auth.signOut();
        throw Exception('Invalid role for this account');
      }

      final loaded = await getUserWithRole(user.uid);
      _cachedUser = loaded;
      return loaded;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? handlerRole,
    String? canteen,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      // Create user profile in Firestore with handler role info
      final userData = {
        'name': name,
        'email': email,
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add handler-specific fields if applicable
      if (role == UserRole.handler) {
        if (handlerRole != null) {
          userData['handlerRole'] = handlerRole;
        }
        if (canteen != null) {
          userData['canteen'] = canteen;
        }
      }

      await _firestore.collection('users').doc(user.uid).set(userData);

      final created = AppUser(
        id: user.uid,
        name: name,
        email: email,
        role: role,
        handlerRole: handlerRole,
        canteen: canteen,
      );

      _cachedUser = created;
      return created;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
  Future<AppUser?> getUserWithRole(String uid) async {
    try {
      print('Getting user document for UID: $uid');
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        print('User document does not exist');
        return null;
      }

      final userData = userDoc.data()!;
      print('User data from Firestore: $userData');
      
      final roleString = userData['role'] as String?;
      print('Role string from Firestore: $roleString');
      
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleString,
        orElse: () {
          print('Role not found, defaulting to student');
          return UserRole.student;
        },
      );

      print('Final role: $role');

      // Load handler-specific data if applicable
      String? handlerRole;
      String? canteen;
      
      if (role == UserRole.handler) {
        handlerRole = userData['handlerRole'] as String?;
        canteen = userData['canteen'] as String?;
        print('Handler role: $handlerRole, Canteen: $canteen');
      }

      return AppUser(
        id: uid,
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: role,
        handlerRole: handlerRole,
        canteen: canteen,
      );
    } catch (e) {
      print('Error in getUserWithRole: $e');
      return null;
    }
  }
}
