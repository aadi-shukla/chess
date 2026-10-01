import 'package:chess/features/splash/presentation/controllers/splash_controller.dart';
import 'package:get/get.dart';

/// Registers [SplashController] for the splash route.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager put — SplashPage does not reference [SplashController], so lazyPut
    // would never instantiate it and onReady navigation would never run.
    Get.put<SplashController>(SplashController());
  }
}
