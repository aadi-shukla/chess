import 'dart:async';

import 'package:chess/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Simple entrance fade for splash and hero sections.
class FadeIn extends StatefulWidget {
  const FadeIn({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.standard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reducedMotion(context)) {
        _controller.value = 1;
        return;
      }
      void start() {
        if (mounted) unawaited(_controller.forward());
      }

      if (widget.delay == Duration.zero) {
        start();
      } else {
        Future<void>.delayed(widget.delay, start);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
