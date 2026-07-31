import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/checkin/checkin_page.dart';
import '../../features/home/home_shell.dart';
import '../../features/plans/plan_form_page.dart';

/// Arguments for opening the check-in screen on a specific plan/date.
class CheckInArgs {
  const CheckInArgs({required this.planId, required this.date});
  final int planId;
  final DateTime date;
}

CustomTransitionPage<void> _fadeThrough(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),
      routes: [
        GoRoute(
          path: 'plan/new',
          pageBuilder: (context, state) =>
              _fadeThrough(const PlanFormPage(), state),
        ),
        GoRoute(
          path: 'plan/:id/edit',
          pageBuilder: (context, state) => _fadeThrough(
            PlanFormPage(planId: int.parse(state.pathParameters['id']!)),
            state,
          ),
        ),
        GoRoute(
          path: 'checkin',
          pageBuilder: (context, state) {
            final extra = state.extra;
            final page = extra is CheckInArgs
                ? CheckInPage(planId: extra.planId, date: extra.date)
                : const CheckInPage();
            return _fadeThrough(page, state);
          },
        ),
      ],
    ),
  ],
);
