import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title shown in the app bar and system UI.
  ///
  /// In en, this message translates to:
  /// **'Chess'**
  String get appTitle;

  /// Message shown on the splash screen while the app initializes.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get splashLoading;

  /// Headline on the home dashboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Chess'**
  String get homeWelcome;

  /// Subtitle on the home dashboard.
  ///
  /// In en, this message translates to:
  /// **'Play offline or challenge players online.'**
  String get homeSubtitle;

  /// Bottom navigation label for home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// Bottom navigation label for leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// Bottom navigation label for profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Theme section label in settings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// System theme option.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Displays the current build flavor.
  ///
  /// In en, this message translates to:
  /// **'Environment: {flavor}'**
  String flavorLabel(String flavor);

  /// Placeholder for features not yet implemented.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Login screen title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginTitle;

  /// Login screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Enter your credentials to continue.'**
  String get authLoginSubtitle;

  /// Registration screen title.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// Registration screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the chess community and track your rating.'**
  String get authRegisterSubtitle;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Confirm password field label.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// Display name field label.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayNameLabel;

  /// Sign in button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Register link/button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// Create account button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// Forgot password link.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Forgot password screen title.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authForgotPasswordTitle;

  /// Forgot password screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link.'**
  String get authForgotPasswordSubtitle;

  /// Send password reset button.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Anonymous sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// Prompt before register link.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// Shown when Firebase is not configured.
  ///
  /// In en, this message translates to:
  /// **'Online sign-in is unavailable. Configure Firebase to enable authentication.'**
  String get authFirebaseUnavailable;

  /// Sign out button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// Delete account button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get authDeleteAccount;

  /// Delete account dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get authDeleteAccountTitle;

  /// Delete account dialog message.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and cannot be undone.'**
  String get authDeleteAccountMessage;

  /// Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// Default name for anonymous users.
  ///
  /// In en, this message translates to:
  /// **'Guest Player'**
  String get authGuestPlayer;

  /// Label for anonymous account chip.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get authGuestAccount;

  /// User rating label.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get authRating;

  /// Subtitle on the play tab.
  ///
  /// In en, this message translates to:
  /// **'Play on this device with a friend.'**
  String get playOfflineSubtitle;

  /// Title for offline local game card.
  ///
  /// In en, this message translates to:
  /// **'Local game'**
  String get playLocalGame;

  /// Description for offline local game card.
  ///
  /// In en, this message translates to:
  /// **'Full rules, timers, undo, and move history.'**
  String get playLocalGameDescription;

  /// Placeholder for online play.
  ///
  /// In en, this message translates to:
  /// **'Online matchmaking — coming soon'**
  String get playOnlineComingSoon;

  /// Title for online multiplayer card.
  ///
  /// In en, this message translates to:
  /// **'Play online'**
  String get playOnline;

  /// Description for online multiplayer card.
  ///
  /// In en, this message translates to:
  /// **'Realtime matchmaking with rated and casual games.'**
  String get playOnlineDescription;

  /// Snackbar when online play is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured on this build.'**
  String get playOnlineUnavailable;

  /// Snackbar when guest tries online play.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an account to play online.'**
  String get playOnlineSignInRequired;

  /// Title for AI game mode card.
  ///
  /// In en, this message translates to:
  /// **'Play vs AI'**
  String get playVsAi;

  /// Description for AI game mode card.
  ///
  /// In en, this message translates to:
  /// **'Challenge the computer at five difficulty levels.'**
  String get playVsAiDescription;

  /// Title for resume saved game card.
  ///
  /// In en, this message translates to:
  /// **'Resume game'**
  String get playResumeGame;

  /// Resume card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{moveCount} moves · {mode}'**
  String playResumeDescription(int moveCount, String mode);

  /// Statistics card title.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get playStatistics;

  /// Statistics card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} games played offline'**
  String playStatisticsDescription(int count);

  /// Game settings section title.
  ///
  /// In en, this message translates to:
  /// **'Offline game'**
  String get settingsGameTitle;

  /// Default clock time setting.
  ///
  /// In en, this message translates to:
  /// **'Default time (minutes)'**
  String get settingsDefaultTime;

  /// Default clock increment setting.
  ///
  /// In en, this message translates to:
  /// **'Default increment'**
  String get settingsDefaultIncrement;

  /// Default AI difficulty setting.
  ///
  /// In en, this message translates to:
  /// **'Default AI difficulty'**
  String get settingsDefaultAiDifficulty;

  /// Board theme setting.
  ///
  /// In en, this message translates to:
  /// **'Board theme'**
  String get settingsBoardTheme;

  /// Haptic feedback toggle.
  ///
  /// In en, this message translates to:
  /// **'Move haptics'**
  String get settingsHaptics;

  /// Auto-save toggle title.
  ///
  /// In en, this message translates to:
  /// **'Auto-save games'**
  String get settingsAutoSave;

  /// Auto-save toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume in-progress games from the Play tab.'**
  String get settingsAutoSaveDescription;

  /// Manual cloud sync button.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get playSyncNow;

  /// Sync in progress status.
  ///
  /// In en, this message translates to:
  /// **'Syncing with cloud…'**
  String get playSyncSyncing;

  /// Offline sync status.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync when connected'**
  String get playSyncOffline;

  /// Sync error status.
  ///
  /// In en, this message translates to:
  /// **'Last sync failed — tap Sync to retry'**
  String get playSyncError;

  /// Idle sync status.
  ///
  /// In en, this message translates to:
  /// **'Cloud save enabled'**
  String get playSyncIdle;

  /// Last successful sync time.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String playSyncLastSynced(String time);

  /// Pending sync operations count.
  ///
  /// In en, this message translates to:
  /// **'{count} changes pending sync'**
  String playSyncPending(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
