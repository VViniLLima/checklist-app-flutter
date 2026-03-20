import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  User? _user;
  bool _isLoading = false;
  String? _localAvatarPath;
  int _avatarVersion = 0;

  AuthController(this._repository) {
    _user = _repository.currentUser;
    _repository.authStateChanges.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
    _loadLocalAvatarPath();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  String? get userName =>
      _repository.getUserName() ?? _user?.userMetadata?['full_name'] as String?;
  String? get userEmail => _user?.email;
  String? get userAvatarUrl => _user?.userMetadata?['avatar_url'] as String?;
  String? get localAvatarPath => _localAvatarPath;
  int get avatarVersion => _avatarVersion;

  Future<void> _loadLocalAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _user?.id;
    if (userId != null) {
      _localAvatarPath = prefs.getString('profile_image_path_$userId');
    }
  }

  Future<void> setLocalAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _user?.id;
    if (userId != null) {
      if (path != null) {
        await prefs.setString('profile_image_path_$userId', path);
      } else {
        await prefs.remove('profile_image_path_$userId');
      }

      final oldPath = _localAvatarPath;
      if (oldPath != null && oldPath != path) {
        await FileImage(File(oldPath)).evict();
      }

      _localAvatarPath = path;
      _avatarVersion++;
      notifyListeners();
    }
  }

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
