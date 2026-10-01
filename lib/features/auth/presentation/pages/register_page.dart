import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chess/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:chess/features/auth/presentation/widgets/auth_loading_overlay.dart';
import 'package:chess/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// New account registration screen.
class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthLoadingOverlay(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.authRegisterTitle)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AuthFormCard(
                title: l10n.authRegisterTitle,
                subtitle: l10n.authRegisterSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => AuthTextField(
                        controller: controller.displayNameController,
                        label: l10n.authDisplayNameLabel,
                        textInputAction: TextInputAction.next,
                        errorText: controller.displayNameError.value.isEmpty
                            ? null
                            : controller.displayNameError.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthTextField(
                        controller: controller.emailController,
                        label: l10n.authEmailLabel,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: controller.emailError.value.isEmpty
                            ? null
                            : controller.emailError.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthTextField(
                        controller: controller.passwordController,
                        label: l10n.authPasswordLabel,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        errorText: controller.passwordError.value.isEmpty
                            ? null
                            : controller.passwordError.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthTextField(
                        controller: controller.confirmPasswordController,
                        label: l10n.authConfirmPasswordLabel,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        errorText: controller.confirmPasswordError.value.isEmpty
                            ? null
                            : controller.confirmPasswordError.value,
                        onSubmitted: (_) => controller.registerWithEmail(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.registerWithEmail,
                        child: Text(l10n.authCreateAccount),
                      ),
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
