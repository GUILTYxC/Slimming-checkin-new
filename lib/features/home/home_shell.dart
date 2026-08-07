import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../checkin/checkin_sheet.dart';
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

  void _onSelect(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _openCheckIn() {
    HapticFeedback.lightImpact();
    showCheckInSheet(context);
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
                  onCheckIn: _openCheckIn,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: _MintNavBar(
            index: _index,
            destinations: _destinations,
            onSelect: _onSelect,
            onCheckIn: _openCheckIn,
          ),
        );
      },
    );
  }
}

/// Custom bottom bar: two tabs on each side of a raised, gradient centre
/// check-in button.
class _MintNavBar extends StatelessWidget {
  const _MintNavBar({
    required this.index,
    required this.destinations,
    required this.onSelect,
    required this.onCheckIn,
  });

  final int index;
  final List<_NavItem> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    if (i == 2) const Spacer(),
                    Expanded(
                      child: _NavTab(
                        item: destinations[i],
                        selected: index == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(top: -18, child: CheckInFab(onPressed: onCheckIn)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's primary action button: a raised mint-gradient disc that opens
/// the check-in sheet. Also used at the top of the wide-screen rail.
class CheckInFab extends StatefulWidget {
  const CheckInFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<CheckInFab> createState() => _CheckInFabState();
}

class _CheckInFabState extends State<CheckInFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: AppMotion.press,
        child: Tooltip(
          message: '打卡',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 4),
              boxShadow: AppShadows.floating,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            child: Icon(
              selected ? item.filled : item.outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.onSelect,
    required this.onCheckIn,
  });

  final int index;
  final List<_NavItem> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheckIn;

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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: AppRadius.smallAll,
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckInFab(onPressed: onCheckIn),
            ],
          ),
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textTertiary,
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
    );
  }
}

class _NavItem {
  const _NavItem(this.filled, this.outlined, this.label);
  final IconData filled;
  final IconData outlined;
  final String label;
}
