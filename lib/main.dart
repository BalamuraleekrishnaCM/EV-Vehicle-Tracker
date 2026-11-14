import 'package:flutter/material.dart';
import 'data/local_store.dart';
import 'features/garage/garage_screen.dart';

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
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF009E87)),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF009E87),
        ),
        themeMode: ThemeMode.system,
        home: GarageScreen(store: LocalStore.instance),
      );
}
