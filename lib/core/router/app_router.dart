import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_shell.dart';
import '../../features/plans/plan_form_page.dart';
import '../theme/app_tokens.dart';

CustomTransitionPage<void> _fadeThrough(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
      );
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
          pageBuilder:
              (context, state) => _fadeThrough(const PlanFormPage(), state),
        ),
        GoRoute(
          path: 'plan/:id/edit',
          pageBuilder:
              (context, state) => _fadeThrough(
                PlanFormPage(planId: int.parse(state.pathParameters['id']!)),
                state,
              ),
        ),
      ],
    ),
  ],
);
