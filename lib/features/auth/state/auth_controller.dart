import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  User? _user;
  bool _isLoading = false;

  AuthController(this._repository) {
    _user = _repository.currentUser;
    _repository.authStateChanges.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  String? get userName =>
      _repository.getUserName() ?? _user?.userMetadata?['full_name'] as String?;
  String? get userEmail => _user?.email;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      await _repository.signUp(email: email, password: password, name: name);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _repository.signIn(email: email, password: password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    // Note: The actual redirect and session handling will be managed by Supabase.
    // The redirect URL must match the configuration in AndroidManifest/Info.plist
    await _repository.signInWithGoogle(
      redirectTo: 'io.checklist.app://login-callback/',
    );
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repository.signOut();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? email,
    String? password,
    String? name,
  }) async {
    _setLoading(true);
    try {
      final response = await _repository.updateUser(
        email: email,
        password: password,
        name: name,
      );
      if (response.user != null) {
        _user = response.user;
      }
    } finally {
      _setLoading(false);
    }
  }
}
