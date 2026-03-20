@GenerateNiceMocks([MockSpec<AuthRepository>()])
library auth_controller_profile_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:checklist_app/features/auth/state/auth_controller.dart';
import 'package:checklist_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'auth_controller_profile_test.mocks.dart';

/// Fake implementation of User for testing purposes.
/// User from supabase_flutter has a const constructor with required fields,
/// and its id property is a final field (not a getter), so it cannot be stubbed
/// with Mockito. We use a Fake implementation instead.
class FakeUser extends Fake implements User {
  FakeUser({
    required this.id,
    this.appMetadata = const {},
    this.userMetadata,
    this.aud = '',
    this.confirmationSentAt,
    this.recoverySentAt,
    this.emailChangeSentAt,
    this.newEmail,
    this.invitedAt,
    this.actionLink,
    this.email,
    this.phone,
    this.createdAt = '',
    this.confirmedAt,
    this.emailConfirmedAt,
    this.phoneConfirmedAt,
    this.lastSignInAt,
    this.role,
    this.updatedAt,
    this.identities,
    this.factors,
    this.isAnonymous = false,
  });

  @override
  final String id;

  @override
  final Map<String, dynamic> appMetadata;

  @override
  final Map<String, dynamic>? userMetadata;

  @override
  final String aud;

  @override
  final String? confirmationSentAt;

  @override
  final String? recoverySentAt;

  @override
  final String? emailChangeSentAt;

  @override
  final String? newEmail;

  @override
  final String? invitedAt;

  @override
  final String? actionLink;

  @override
  final String? email;

  @override
  final String? phone;

  @override
  final String createdAt;

  @override
  final String? confirmedAt;

  @override
  final String? emailConfirmedAt;

  @override
  final String? phoneConfirmedAt;

  @override
  final String? lastSignInAt;

  @override
  final String? role;

  @override
  final String? updatedAt;

  @override
  final List<UserIdentity>? identities;

  @override
  final List<Factor>? factors;

  @override
  final bool isAnonymous;
}

void main() {
  // Initialize Flutter binding for tests that use FileImage.evict()
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late MockAuthRepository mockRepository;
  late FakeUser fakeUser;
  late StreamController<AuthState> authStateController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockRepository = MockAuthRepository();
    fakeUser = FakeUser(id: 'test-user-id');
    authStateController = StreamController<AuthState>.broadcast();

    // Stub the auth state changes stream
    when(
      mockRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);

    // Stub the current user
    when(mockRepository.currentUser).thenReturn(fakeUser);

    // Stub getUserName to return null (default behavior for NiceMock)
    when(mockRepository.getUserName()).thenReturn(null);

    authController = AuthController(mockRepository);
  });

  tearDown(() {
    authStateController.close();
  });

  group('AuthController Profile Picture Tests', () {
    test('initial avatar version is 0', () {
      expect(authController.avatarVersion, 0);
    });

    test(
      'setLocalAvatarPath increments avatar version and notifies listeners',
      () async {
        int listenerCount = 0;
        authController.addListener(() {
          listenerCount++;
        });

        await authController.setLocalAvatarPath('new/path/to/image.jpg');

        expect(authController.localAvatarPath, 'new/path/to/image.jpg');
        expect(authController.avatarVersion, 1);
        expect(listenerCount, 1);
      },
    );

    test('multiple updates increment version multiple times', () async {
      await authController.setLocalAvatarPath('path1.jpg');
      expect(authController.avatarVersion, 1);

      await authController.setLocalAvatarPath('path2.jpg');
      expect(authController.avatarVersion, 2);
    });

    test('setting null path increments version (clearing image)', () async {
      await authController.setLocalAvatarPath('path1.jpg');
      expect(authController.avatarVersion, 1);

      await authController.setLocalAvatarPath(null);
      expect(authController.localAvatarPath, null);
      expect(authController.avatarVersion, 2);
    });
  });
}
