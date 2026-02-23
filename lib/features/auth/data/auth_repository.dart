import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<void> signInWithGoogle({required String redirectTo}) async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    String? name,
  }) async {
    return await _supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: name != null ? {'full_name': name} : null,
      ),
    );
  }

  String? getUserName() {
    final user = currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;
    return (metadata?['full_name'] as String?) ??
        (metadata?['name'] as String?) ??
        user.email?.split('@').first;
  }

  String? getUserEmail() {
    return currentUser?.email;
  }
}
