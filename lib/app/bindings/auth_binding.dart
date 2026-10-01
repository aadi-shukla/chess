import 'dart:async';

import 'package:chess/core/firebase/firebase_bootstrap.dart';
import 'package:chess/core/firebase/firestore_service.dart';
import 'package:chess/core/firebase/functions_service.dart';
import 'package:chess/core/utils/app_logger.dart';
import 'package:chess/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:chess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chess/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:chess/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chess/features/auth/data/repositories/unavailable_auth_repository.dart';
import 'package:chess/features/auth/data/services/auth_service.dart';
import 'package:chess/features/auth/data/services/auth_service_impl.dart';
import 'package:chess/features/auth/domain/repositories/auth_repository.dart';
import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:get/get.dart';

/// Registers authentication dependencies and session controller.
abstract final class AuthBinding {
  /// Binds auth layer — real implementation when Firebase is ready, stub otherwise.
  static void register() {
    Get.put<AuthLocalDataSource>(AuthLocalDataSource(), permanent: true);

    if (FirebaseBootstrap.isInitialized) {
      Get
        ..put<AuthService>(AuthServiceImpl(), permanent: true)
        ..put<FirestoreService>(FirestoreServiceImpl(), permanent: true)
        ..put<FunctionsService>(FunctionsServiceImpl(), permanent: true)
        ..put<AuthRemoteDataSource>(
          AuthRemoteDataSource(Get.find<AuthService>()),
          permanent: true,
        )
        ..put<UserRemoteDataSource>(
          UserRemoteDataSource(Get.find<FirestoreService>()),
          permanent: true,
        )
        ..put<AuthRepository>(
          AuthRepositoryImpl(
            authRemoteDataSource: Get.find<AuthRemoteDataSource>(),
            userRemoteDataSource: Get.find<UserRemoteDataSource>(),
            authLocalDataSource: Get.find<AuthLocalDataSource>(),
          ),
          permanent: true,
        );
      AppLogger.instance.i('Auth repository (Firebase) registered.');
    } else {
      Get.put<AuthRepository>(UnavailableAuthRepository(), permanent: true);
      AppLogger.instance.w('Auth repository unavailable — Firebase not initialized.');
    }

    Get
      ..put<AuthSessionController>(AuthSessionController(), permanent: true)
      ..put<AuthController>(AuthController(), permanent: true);
  }

  /// Starts session listener after all bindings are registered.
  static Future<void> initializeSession() async {
    if (Get.isRegistered<AuthSessionController>()) {
      await Get.find<AuthSessionController>().init();
    }
  }
}
