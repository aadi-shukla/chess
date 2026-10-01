import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chess/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:chess/features/auth/presentation/widgets/auth_loading_overlay.dart';
import 'package:chess/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Password reset request screen.
class ForgotPasswordPage extends GetView<AuthController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthLoadingOverlay(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.authForgotPasswordTitle)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AuthFormCard(
                title: l10n.authForgotPasswordTitle,
                subtitle: l10n.authForgotPasswordSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => AuthTextField(
                        controller: controller.emailController,
                        label: l10n.authEmailLabel,
                        keyboardType: TextInputType.emailAddress,
                        errorText: controller.emailError.value.isEmpty
                            ? null
                            : controller.emailError.value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.sendPasswordReset,
                        child: Text(l10n.authSendResetLink),
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
