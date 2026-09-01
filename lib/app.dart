import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_glass.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_controller.dart';

class SlimmingCheckInApp extends ConsumerWidget {
  const SlimmingCheckInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return GlassBackdrop(
      child: MaterialApp.router(
        title: '轻盈打卡',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
