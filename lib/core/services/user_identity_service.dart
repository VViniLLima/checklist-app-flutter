import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/state/auth_controller.dart';

/// Service that manages user identity for data isolation.
///
/// Provides a stable owner ID for both guest and authenticated users:
/// - Guest users: persistent device-specific guest ID (guest_<uuid>)
/// - Authenticated users: Supabase user ID
///
/// This ensures data isolation between different users and between guest/auth sessions.
class UserIdentityService extends ChangeNotifier {
  static const String _guestIdKey = 'guest_owner_id';

  String? _guestId;
  String? _authenticatedUserId;
  bool _isInitialized = false;

  /// The current owner ID for data scoping.
  ///
  /// Returns the authenticated user ID if logged in, otherwise the guest ID.
  String get currentOwnerId {
    if (_authenticatedUserId != null && _authenticatedUserId!.isNotEmpty) {
      return _authenticatedUserId!;
    }
    return _guestId ?? '';
  }

  /// Whether the current user is authenticated.
  bool get isAuthenticated =>
      _authenticatedUserId != null && _authenticatedUserId!.isNotEmpty;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initialize the service.
  ///
  /// Loads or generates a persistent guest ID and sets up auth state listening.
  Future<void> initialize(AuthController authController) async {
    if (_isInitialized) return;

    // Load or generate persistent guest ID
    await _loadOrGenerateGuestId();

    // Listen to auth state changes
    authController.addListener(_onAuthStateChanged);

    // Set initial auth state
    _onAuthStateChanged();

    _isInitialized = true;
    notifyListeners();
  }

  /// Load or generate a persistent guest ID.
  Future<void> _loadOrGenerateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    _guestId = prefs.getString(_guestIdKey);

    if (_guestId == null || _guestId!.isEmpty) {
      // Generate a new guest ID
      _guestId = 'guest_${_generateUUID()}';
      await prefs.setString(_guestIdKey, _guestId!);
    }
  }

  /// Generate a simple UUID v4-like string.
  String _generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version bits (4) and variant bits (8, 9, A, or B)
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 1

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Handle auth state changes from AuthController.
  void _onAuthStateChanged() {
    // This will be called when AuthController notifies
    // We'll get the current user ID from the controller
    // The actual implementation will be done via a callback or direct access
  }

  /// Update the authenticated user ID.
  ///
  /// Called when auth state changes (login/logout).
  void updateAuthenticatedUserId(String? userId) {
    if (_authenticatedUserId != userId) {
      _authenticatedUserId = userId;
      notifyListeners();
    }
  }

  /// Get the guest ID (for debugging purposes).
  String? get guestId => _guestId;

  /// Get the authenticated user ID (for debugging purposes).
  String? get authenticatedUserId => _authenticatedUserId;
}
