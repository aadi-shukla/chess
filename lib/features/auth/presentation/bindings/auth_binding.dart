import 'package:get/get.dart';

/// Route-level binding for auth screens (controller registered globally).
class AuthPresentationBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController and AuthSessionController are registered in [AuthBinding].
  }
}
