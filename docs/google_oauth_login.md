# Google OAuth Login Setup Guide

This document explains how Google OAuth login is implemented in the Checklist App and what configurations are required in Supabase and Google Cloud.

## How it Works
1.  **Trigger**: The user taps the Google button on the Login screen.
2.  **Request**: The app calls `supabase.auth.signInWithOAuth(OAuthProvider.google, ...)` with a custom redirect URL.
3.  **Authentication**: The app opens the system browser for the user to choose their Google account.
4.  **Redirect**: After success, Google redirects back to Supabase, which then redirects to our app using the custom scheme `io.checklist.app://login-callback/`.
5.  **Completion**: The `SplashScreen` listens for `AuthChangeEvent.signedIn` and redirects the user to the `MainScreen`.

## Required Configurations

### 1. Supabase Dashboard
- **Enable Google Provider**: Go to `Authentication -> Providers -> Google`.
- **Whitedlist Redirect URL**: Add `io.checklist.app://login-callback/` to the "Additional Redirect URLs" in `Authentication -> URL Configuration`.

### 2. Google Cloud Console
- Create an **OAuth Web Client ID** (not Android/iOS, as Supabase manages the cross-platform flow).
- In Supabase's Google Provider settings, enter the **Client ID** and **Client Secret**.

### 3. Flutter Deep Link Config

#### Android (`android/app/src/main/AndroidManifest.xml`)
The following intent filter was added to `MainActivity`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.checklist.app" android:host="login-callback" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)
The following URL type was added:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.checklist.app</string>
    </array>
  </dict>
</array>
```

## Troubleshooting
- **Redirect Mismatch**: Ensure the URL in `AuthRepository` matches EXACTLY what is whitelisted in Supabase.
- **Null Session**: Ensure deep links are correctly configured; otherwise, the app won't receive the session token after returning from the browser.
- **Navigation Loop**: The `SplashScreen` uses a listener to prevent double navigation.
