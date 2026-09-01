import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../dashboard/dashboard_page.dart';
import '../history/history_page.dart';
import '../plans/plans_page.dart';
import '../settings/settings_page.dart';
import '../../core/theme/app_palette.dart';

/// App shell holding the four top-level destinations.
///
/// Navigation is a floating pill tab bar rather than a docked bar with a
/// raised action button: the check-in entry point now lives as the first
/// card on the overview screen, so the bar can stay flat and quiet.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    HistoryPage(),
    PlansPage(),
    SettingsPage(),
  ];

  static const _destinations = [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, '概览'),
    _NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, '历史'),
    _NavItem(Icons.flag_rounded, Icons.flag_outlined, '计划'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, '设置'),
  ];

  void _onSelect(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.emphasized,
      transitionBuilder:
          (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
      child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _SideRail(
                  index: _index,
                  destinations: _destinations,
                  onSelect: _onSelect,
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: body,
          bottomNavigationBar: _PillTabBar(
            index: _index,
            destinations: _destinations,
            onSelect: _onSelect,
          ),
        );
      },
    );
  }
}

/// Floating pill tab bar: a rounded capsule with four equal tabs. The
/// selected tab is a solid accent fill so the active state is unmistakable.
class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.index,
    required this.destinations,
    required this.onSelect,
  });

  final int index;
  final List<_NavItem> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: GlassSurface(
          thickness: GlassThickness.thick,
          radius: 36,
          height: 62,
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _TabItem(
                    item: destinations[i],
                    selected: index == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : context.palette.textTertiary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          decoration: BoxDecoration(
            color: selected ? context.palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.filled : item.outlined, color: color, size: 18),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide-window navigation rail. Kept deliberately simple — it is the same
/// four destinations, just docked to the side.
class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.onSelect,
  });

  final int index;
  final List<_NavItem> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      thickness: GlassThickness.thick,
      radius: 0,
      sheen: false,
      child: SafeArea(
        child: NavigationRail(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          backgroundColor: Colors.transparent,
          labelType: NavigationRailLabelType.all,
          indicatorColor: context.palette.primary,
          groupAlignment: -0.85,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.palette.primary,
                borderRadius: AppRadius.smallAll,
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white),
            ),
          ),
          selectedIconTheme: const IconThemeData(color: Colors.white),
          unselectedIconTheme: IconThemeData(
            color: context.palette.textTertiary,
          ),
          selectedLabelTextStyle: TextStyle(
            color: context.palette.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: context.palette.textTertiary,
            fontSize: 12,
          ),
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(
                icon: Icon(d.outlined),
                selectedIcon: Icon(d.filled),
                label: Text(d.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.filled, this.outlined, this.label);
  final IconData filled;
  final IconData outlined;
  final String label;
}
