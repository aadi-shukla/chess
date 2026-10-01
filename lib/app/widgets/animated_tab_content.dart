import 'package:chess/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Cross-fades tab content with a subtle vertical slide.
class AnimatedTabContent extends StatelessWidget {
  const AnimatedTabContent({
    required this.tabKey,
    required this.child,
    super.key,
  });

  final Object tabKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.tabSwitch(context);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: widget),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(tabKey),
        child: child,
      ),
    );
  }
}
