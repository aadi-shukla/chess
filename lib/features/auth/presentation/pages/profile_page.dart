import 'package:chess/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chess/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:chess/features/auth/presentation/widgets/auth_loading_overlay.dart';
import 'package:chess/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Profile tab showing user info, logout, and delete account.
class ProfilePage extends GetView<AuthController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = Get.find<AuthSessionController>();

    return AuthLoadingOverlay(
      child: Obx(() {
        final user = session.user.value;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (user?.displayName.isNotEmpty ?? false
                        ? user!.displayName[0]
                        : '?')
                    .toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? l10n.authGuestPlayer,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user?.email.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (user?.isAnonymous ?? false) ...[
              const SizedBox(height: 8),
              Chip(label: Text(l10n.authGuestAccount)),
            ],
            const SizedBox(height: 8),
            Text('${l10n.authRating}: ${user?.rating ?? 1200}'),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: controller.isLoading.value ? null : controller.signOut,
              child: Text(l10n.authSignOut),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => _confirmDelete(context, l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: Text(l10n.authDeleteAccount),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(l10n.authDeleteAccountTitle),
        content: Text(l10n.authDeleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: Text(l10n.authCancel),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.authDeleteAccount),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await controller.deleteAccount();
    }
  }
}
