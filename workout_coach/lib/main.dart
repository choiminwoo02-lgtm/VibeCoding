import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/db/platform_database.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDesktopDatabase();
  await initializeDateFormatting('ko_KR', null);
  runApp(const ProviderScope(child: WorkoutCoachApp()));
}
