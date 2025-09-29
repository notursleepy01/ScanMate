import 'package:flutter/material.dart';
import 'package:scanmate/screens/home_screen.dart';
import 'package:scanmate/services/storage_service.dart'; // Import StorageService

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await StorageService.initHive(); // Initialize Hive
  runApp(const ScanMateApp());
}

class ScanMateApp extends StatefulWidget {
  const ScanMateApp({super.key});

  @override
  State<ScanMateApp> createState() => _ScanMateAppState();
}

class _ScanMateAppState extends State<ScanMateApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _changeThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  // Expose a method to change theme for potential settings screen later
  static _ScanMateAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ScanMateAppState>();

  void setThemeMode(ThemeMode mode) => _changeThemeMode(mode);
  ThemeMode get currentThemeMode => _themeMode;


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanMate',
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        // Further light theme customizations can go here
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        // Further dark theme customizations can go here
      ),
      home: const HomeScreen(),
    );
  }
}
