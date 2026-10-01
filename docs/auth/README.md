# Authentication — Phase 4

Production authentication for the Chess app: email, Google, guest, session restore, and account management.

## Architecture

```
LoginPage / RegisterPage / ProfilePage
        ↓
  AuthController
        ↓
  AuthRepository (interface)
        ↓
  AuthRepositoryImpl
    ├── AuthRemoteDataSource → AuthService → Firebase Auth
    ├── UserRemoteDataSource → FirestoreService → Firestore
    └── AuthLocalDataSource → Hive (session cache)
        ↓
  AuthSessionController (global session + auto-login)
```

## Features

| Feature | Implementation |
|---------|----------------|
| Email login | `AuthController.signInWithEmail` |
| Registration | `AuthController.registerWithEmail` + `ensureUserProfile` |
| Google login | `AuthService.signInWithGoogle` (popup on web, SDK on mobile) |
| Guest login | `AuthRepository.signInAnonymously` |
| Forgot password | `AuthController.sendPasswordReset` |
| Delete account | `AuthController.deleteAccount` → `user.delete()` |
| Logout | `AuthController.signOut` |
| Session restore | `AuthSessionController` + Hive cache + `authStateChanges` |
| Auto login | Splash waits for session restore → routes to home |

## Firestore User Document

Path: `users/{uid}`

```json
{
  "email": "player@example.com",
  "displayName": "Player",
  "photoUrl": null,
  "rating": 1200,
  "stats": { "played": 0, "wins": 0, "losses": 0, "draws": 0 },
  "activeGameId": null,
  "isAnonymous": false,
  "createdAt": "<server timestamp>",
  "updatedAt": "<server timestamp>"
}
```

Created by Cloud Function `onAuthUserCreate` or client `ensureUserProfile` (emulator fallback).

## Security Rules

- Users can **create** own profile with `rating: 1200` and zero stats
- Users **cannot** modify `rating`, `stats`, `globalRank`, `activeGameId`
- Account deletion removes Firebase Auth user; Firestore doc retained (rules: `delete: false`)

## Manual Test Cases

### Email login
1. Open app → login screen
2. Enter valid credentials → home screen
3. Kill app → relaunch → auto-login to home

### Registration
1. Tap Register → fill all fields → create account
2. Verify Firestore `users/{uid}` document exists
3. Verify default rating is 1200

### Google login
1. Tap Continue with Google → complete OAuth
2. Profile shows Google display name

### Guest login
1. Tap Continue as guest → home
2. Profile shows "Guest account" chip

### Forgot password
1. Enter email → Send reset link
2. Check email for Firebase reset message

### Logout
1. Profile → Sign out → login screen
2. Relaunch app → login screen (no auto-login)

### Delete account
1. Profile → Delete account → confirm
2. Auth user removed; redirected to login

## Edge Cases

| Case | Expected behavior |
|------|-------------------|
| Firebase not configured | Login shows warning; buttons disabled |
| Invalid email format | Inline validation error |
| Weak password on register | Inline validation error |
| Wrong password | Snackbar with mapped error |
| Google sign-in cancelled | Snackbar "cancelled" |
| Delete without recent login | `requires-recent-login` error message |
| Network offline during sign-in | `AuthNetworkFailure` snackbar |
| Anonymous user | `isAnonymous: true`, display "Guest Player" |
| Emulator without Functions | Client creates Firestore profile |

## Running Tests

```bash
flutter test test/unit/auth/
```

## Routes

| Route | Page | Middleware |
|-------|------|------------|
| `/login` | LoginPage | — |
| `/register` | RegisterPage | — |
| `/forgot-password` | ForgotPasswordPage | — |
| `/home` | HomePage | AuthMiddleware |
| `/settings` | SettingsPage | AuthMiddleware |
