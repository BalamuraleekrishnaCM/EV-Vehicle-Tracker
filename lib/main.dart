import 'package:flutter/material.dart';
import 'data/local_store.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'ui/ev_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EvTrackerApp());
}

class EvTrackerApp extends StatelessWidget {
  const EvTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EV Vehicle Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildEvTheme(),
        home: DashboardShell(store: LocalStore.instance),
      );
}
