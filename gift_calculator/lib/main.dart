import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/calculator_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GiftCalculatorApp());
}

class GiftCalculatorApp extends StatefulWidget {
  const GiftCalculatorApp({super.key});

  @override
  State<GiftCalculatorApp> createState() => _GiftCalculatorAppState();
}

class _GiftCalculatorAppState extends State<GiftCalculatorApp> {
  static const _themeKey = 'gift_calculator_theme_pref';

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (!mounted || saved == null) return;
    setState(() {
      _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final current = _themeMode == ThemeMode.system
        ? SchedulerBinding.instance.platformDispatcher.platformBrightness
        : (_themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    final next = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, next == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '축의금 계산기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      // No splash, no login, no home page: the calculator is the app.
      home: CalculatorScreen(themeMode: _themeMode, onToggleTheme: _toggleTheme),
    );
  }
}
