import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_page.dart';
import '../history/history_page.dart';
import '../plans/plans_page.dart';
import '../settings/settings_page.dart';

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

  void _onSelect(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_index),
        child: _pages[_index],
      ),
    );

    final fab = _index == 0
        ? FloatingActionButton.extended(
            onPressed: () => context.push('/checkin'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text(
              '打卡',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            floatingActionButton: fab,
            body: Row(
              children: [
                _SideRail(
                  index: _index,
                  destinations: _destinations,
                  onSelect: _onSelect,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          floatingActionButton: fab,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onSelect,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.outlined),
                  selectedIcon: Icon(d.filled),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

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
    return Container(
      color: AppColors.surface,
      child: NavigationRail(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        backgroundColor: AppColors.surface,
        labelType: NavigationRailLabelType.all,
        indicatorColor: AppColors.primarySoft,
        groupAlignment: -0.85,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white),
          ),
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle:
            const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.outlined),
              selectedIcon: Icon(d.filled),
              label: Text(d.label),
            ),
        ],
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
