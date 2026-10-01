// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chess';

  @override
  String get splashLoading => 'Loading…';

  @override
  String get homeWelcome => 'Welcome to Chess';

  @override
  String get homeSubtitle => 'Play offline or challenge players online.';

  @override
  String get navHome => 'Home';

  @override
  String get navPlay => 'Play';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String flavorLabel(String flavor) {
    return 'Environment: $flavor';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle =>
      'Welcome back. Enter your credentials to continue.';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle =>
      'Join the chess community and track your rating.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authDisplayNameLabel => 'Display name';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordTitle => 'Reset password';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email and we will send a reset link.';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authFirebaseUnavailable =>
      'Online sign-in is unavailable. Configure Firebase to enable authentication.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authDeleteAccount => 'Delete account';

  @override
  String get authDeleteAccountTitle => 'Delete account?';

  @override
  String get authDeleteAccountMessage =>
      'This permanently deletes your account and cannot be undone.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authGuestPlayer => 'Guest Player';

  @override
  String get authGuestAccount => 'Guest account';

  @override
  String get authRating => 'Rating';

  @override
  String get playOfflineSubtitle => 'Play on this device with a friend.';

  @override
  String get playLocalGame => 'Local game';

  @override
  String get playLocalGameDescription =>
      'Full rules, timers, undo, and move history.';

  @override
  String get playOnlineComingSoon => 'Online matchmaking — coming soon';

  @override
  String get playOnline => 'Play online';

  @override
  String get playOnlineDescription =>
      'Realtime matchmaking with rated and casual games.';

  @override
  String get playOnlineUnavailable =>
      'Firebase is not configured on this build.';

  @override
  String get playOnlineSignInRequired =>
      'Sign in with an account to play online.';

  @override
  String get playVsAi => 'Play vs AI';

  @override
  String get playVsAiDescription =>
      'Challenge the computer at five difficulty levels.';

  @override
  String get playResumeGame => 'Resume game';

  @override
  String playResumeDescription(int moveCount, String mode) {
    return '$moveCount moves · $mode';
  }

  @override
  String get playStatistics => 'Statistics';

  @override
  String playStatisticsDescription(int count) {
    return '$count games played offline';
  }

  @override
  String get settingsGameTitle => 'Offline game';

  @override
  String get settingsDefaultTime => 'Default time (minutes)';

  @override
  String get settingsDefaultIncrement => 'Default increment';

  @override
  String get settingsDefaultAiDifficulty => 'Default AI difficulty';

  @override
  String get settingsBoardTheme => 'Board theme';

  @override
  String get settingsHaptics => 'Move haptics';

  @override
  String get settingsAutoSave => 'Auto-save games';

  @override
  String get settingsAutoSaveDescription =>
      'Resume in-progress games from the Play tab.';

  @override
  String get playSyncNow => 'Sync';

  @override
  String get playSyncSyncing => 'Syncing with cloud…';

  @override
  String get playSyncOffline => 'Offline — changes will sync when connected';

  @override
  String get playSyncError => 'Last sync failed — tap Sync to retry';

  @override
  String get playSyncIdle => 'Cloud save enabled';

  @override
  String playSyncLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String playSyncPending(int count) {
    return '$count changes pending sync';
  }
}
