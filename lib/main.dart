import 'package:flutter/material.dart';
import 'screens/bms_dashboard_screen.dart';

void main() {
  runApp(const BmsApp());
}

class BmsApp extends StatelessWidget {
  const BmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF00E5FF); // Electric Cyan / Minimal BMS Accent

    return MaterialApp(
      title: 'BMS Monitor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Follows system light/dark mode
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1318),
      ),
      home: const BmsDashboardScreen(),
    );
  }
}
