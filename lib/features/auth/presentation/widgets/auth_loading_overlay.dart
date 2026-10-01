import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen loading overlay during auth operations.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Stack(
      children: [
        child,
        Obx(
          () => controller.isLoading.value
              ? ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
