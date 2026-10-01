import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';

/// Centers page content with responsive max-width and padding.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.alignment = Alignment.topCenter,
    this.padding,
    super.key,
  });

  final Widget child;
  final Alignment alignment;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth(context),
        ),
        child: Padding(
          padding: padding ?? AppBreakpoints.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
