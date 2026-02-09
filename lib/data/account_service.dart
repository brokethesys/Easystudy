import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'game_state.dart';

class AccountService {
  AccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  Future<bool> isSignedIn() async {
    return _auth.currentUser != null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AuthResult> register({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after registration',
      );
    }

    await _saveConfig(user.uid, state.toConfigMap());

    return AuthResult(
      token: user.uid,
      configApplied: false,
    );
  }

  Future<AuthResult> login({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User is null after login',
      );
    }

    bool applied = false;
    final config = await _loadConfig(user.uid);
    if (config != null) {
      await state.applyConfigMap(config);
      applied = true;
    }

    return AuthResult(
      token: user.uid,
      configApplied: applied,
    );
  }

  Future<void> syncUp(GameState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRequiredException();
    }
    await _saveConfig(user.uid, state.toConfigMap());
  }

  Future<bool> syncDown(GameState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRequiredException();
    }
    final config = await _loadConfig(user.uid);
    if (config == null) return false;
    await state.applyConfigMap(config);
    return true;
  }

  Future<Map<String, dynamic>?> _loadConfig(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final config = data['config'];
    return config is Map<String, dynamic> ? config : null;
  }

  Future<void> _saveConfig(String uid, Map<String, dynamic> config) async {
    await _firestore.collection(_usersCollection).doc(uid).set(
      {
        'config': config,
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 1,
      },
      SetOptions(merge: true),
    );
  }
}

class AuthResult {
  AuthResult({required this.token, required this.configApplied});

  final String token;
  final bool configApplied;
}

class AuthRequiredException implements Exception {
  const AuthRequiredException();
}
