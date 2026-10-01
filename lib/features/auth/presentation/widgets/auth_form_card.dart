import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';

/// Responsive centered card for authentication forms.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: AppBreakpoints.isDesktop(context) ? 420 : 480,
      ),
      child: AuthFormCardInner(
        title: title,
        subtitle: subtitle,
        child: child,
      ),
    );
  }
}

/// Inner card content separated for testing.
class AuthFormCardInner extends StatelessWidget {
  const AuthFormCardInner({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
