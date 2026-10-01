import 'package:chess/app/middleware/auth_middleware.dart';
import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/features/auth/presentation/bindings/auth_binding.dart';
import 'package:chess/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:chess/features/auth/presentation/pages/login_page.dart';
import 'package:chess/features/auth/presentation/pages/register_page.dart';
import 'package:chess/features/game/domain/entities/game_mode.dart';
import 'package:chess/features/game/presentation/bindings/game_binding.dart';
import 'package:chess/features/game/presentation/bindings/offline_game_binding.dart';
import 'package:chess/features/game/presentation/pages/game_setup_page.dart';
import 'package:chess/features/game/presentation/pages/game_statistics_page.dart';
import 'package:chess/features/game/presentation/pages/offline_game_page.dart';
import 'package:chess/features/home/presentation/bindings/home_binding.dart';
import 'package:chess/features/home/presentation/pages/home_page.dart';
import 'package:chess/features/online/presentation/bindings/online_binding.dart';
import 'package:chess/features/online/presentation/pages/matchmaking_page.dart';
import 'package:chess/features/online/presentation/pages/online_game_page.dart';
import 'package:chess/features/settings/presentation/bindings/settings_binding.dart';
import 'package:chess/features/settings/presentation/pages/settings_page.dart';
import 'package:chess/features/splash/presentation/bindings/splash_binding.dart';
import 'package:chess/features/splash/presentation/pages/splash_page.dart';
import 'package:get/get.dart';

/// Central registry of [GetPage] route definitions.
abstract final class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashPage.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginPage.new,
      binding: AuthPresentationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: RegisterPage.new,
      binding: AuthPresentationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: ForgotPasswordPage.new,
      binding: AuthPresentationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: HomePage.new,
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: SettingsPage.new,
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.offlineGame,
      page: OfflineGamePage.new,
      binding: OfflineGameBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.gameSetup,
      page: () => GameSetupPage(
        initialMode: Get.arguments as GameMode? ?? GameMode.playerVsPlayer,
      ),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.gameStatistics,
      page: GameStatisticsPage.new,
      binding: PlayTabBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.matchmaking,
      page: MatchmakingPage.new,
      binding: OnlineBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.onlineGame,
      page: OnlineGamePage.new,
      binding: OnlineGameBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.cupertino,
    ),
  ];
}
