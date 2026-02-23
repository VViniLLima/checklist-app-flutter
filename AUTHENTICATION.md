# Authentication System Documentation (Supabase)

This document explains the implementation of the authentication system in the Checklist app using Supabase.

## Overview

The authentication system is built using the official `supabase_flutter` SDK. It currently supports **Email and Password** authentication as Phase 1.

## Supabase Configuration

### 1. Environment Variables
You need to provide your Supabase credentials in the `.env` file at the root of the project:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

### 2. Initialization
Supabase is initialized in `lib/main.dart` before the app starts:

```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
);
```

## How it Works

### Architecture
- **`AuthRepository`**: Low-level service that interacts directly with the Supabase client.
- **`AuthController`**: State manager (using `ChangeNotifier`) that exposes authentication state and actions to the UI.
- **`Provider`**: Used for dependency injection and state propagation.

### User Metadata
During registration, the user's name is stored in the `user_metadata` field of the Supabase auth record:

```dart
await _supabase.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': name},
);
```

This name is retrieved and used in the Home and Settings screens.

### Session Persistence
Supabase automatically persists the user session in local storage. On app startup, `SplashScreen` checks if a valid session exists:

```dart
final authController = context.read<AuthController>();
if (authController.isAuthenticated) {
  // Redirect to Home
}
```

### Security Requirements (Password)
- At least 6 characters.
- At least one uppercase letter.
- Validated locally in `SignupBottomSheet`.

## Important Snippets

### Sign In
```dart
await authController.signIn(
  email: email,
  password: password,
);
```

### Sign Up with Name
```dart
await authController.signUp(
  email: email,
  password: password,
  name: name,
);
```

### Get User Info
```dart
final name = authController.userName;
final email = authController.userEmail;
```

## Future Extensions

### Social Login (e.g., Google)
To implement Google login, you would:
1. Configure Google Auth in your Supabase dashboard.
2. Update `AuthRepository` to include:
   ```dart
   await _supabase.auth.signInWithOAuth(OAuthProvider.google);
   ```
3. Update the UI to call this method from the Google button.

### Email Confirmation
Currently, "Auto Confirm" should be enabled in Supabase for testing. If disabled, users must click a link in their email before being able to log in.
