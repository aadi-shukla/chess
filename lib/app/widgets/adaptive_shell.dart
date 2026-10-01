import 'package:chess/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';

/// Destination metadata for adaptive navigation shells.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? semanticLabel;
}

/// Bottom bar on mobile, [NavigationRail] on tablet/desktop/web.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.useNavigationRail(context)) {
      return _RailLayout(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        body: body,
      );
    }

    return _BarLayout(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      body: body,
    );
  }
}

class _BarLayout extends StatelessWidget {
  const _BarLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: body),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                tooltip: d.semanticLabel ?? d.label,
              ),
          ],
        ),
      ],
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final extended = AppBreakpoints.isDesktop(context);

    return Row(
      children: [
        NavigationRail(
          extended: extended,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.selected,
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ],
    );
  }
}
