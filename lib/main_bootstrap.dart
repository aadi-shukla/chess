import 'package:chess/app/app.dart';
import 'package:chess/app/bindings/auth_binding.dart';
import 'package:chess/app/bindings/initial_binding.dart';
import 'package:chess/app/config/app_bootstrap.dart';
import 'package:chess/features/game/presentation/bindings/game_binding.dart';
import 'package:chess/features/game/presentation/controllers/game_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared startup sequence for all flavor entry points.
Future<void> runChessApp() async {
  await AppBootstrap.initialize();

  InitialBinding().dependencies();
  AuthBinding.register();
  GameBinding.register();

  await InitialBinding.initializeAsyncServices();
  await Get.find<GameSettingsController>().load();
  await AuthBinding.initializeSession();

  runApp(const ChessApp());
}
