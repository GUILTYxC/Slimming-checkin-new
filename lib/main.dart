import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/services/checkin_reminder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Restore the daily reminder if the user left it on.
  if (prefs.getBool('settings.reminderEnabled') ?? false) {
    await CheckInReminder.scheduleDaily(
      hour: prefs.getInt('settings.reminderHour') ?? 20,
      minute: prefs.getInt('settings.reminderMinute') ?? 0,
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SlimmingCheckInApp(),
    ),
  );
}
