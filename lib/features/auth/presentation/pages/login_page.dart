import 'package:chess/app/routes/app_routes.dart';
import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chess/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:chess/features/auth/presentation/widgets/auth_loading_overlay.dart';
import 'package:chess/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Email and password sign-in screen.
class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthLoadingOverlay(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AuthFormCard(
                title: l10n.authLoginTitle,
                subtitle: l10n.authLoginSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!controller.isAuthAvailable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.authFirebaseUnavailable,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Obx(
                      () => AuthTextField(
                        controller: controller.emailController,
                        label: l10n.authEmailLabel,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: controller.emailError.value.isEmpty
                            ? null
                            : controller.emailError.value,
                        autofillHints: const [AutofillHints.email],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthTextField(
                        controller: controller.passwordController,
                        label: l10n.authPasswordLabel,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        errorText: controller.passwordError.value.isEmpty
                            ? null
                            : controller.passwordError.value,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => controller.signInWithEmail(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                        child: Text(l10n.authForgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value ||
                                !controller.isAuthAvailable
                            ? null
                            : controller.signInWithEmail,
                        child: Text(l10n.authSignIn),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.isAuthAvailable
                          ? controller.signInWithGoogle
                          : null,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(l10n.authContinueWithGoogle),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: controller.isAuthAvailable
                          ? controller.signInAsGuest
                          : null,
                      child: Text(l10n.authContinueAsGuest),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.authNoAccount),
                        TextButton(
                          onPressed: () => Get.toNamed<void>(AppRoutes.register),
                          child: Text(l10n.authRegister),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
