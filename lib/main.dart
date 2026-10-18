import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UnexPlayApp());
}

class UnexPlayApp extends StatelessWidget {
  const UnexPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D9FF);
    return MaterialApp(
      title: 'UNEX PLAY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF090B10),
        cardColor: const Color(0xFF151922),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF090B10), surfaceTintColor: Colors.transparent),
        focusColor: accent.withValues(alpha: 0.22),
      ),
      home: const HomeScreen(),
    );
  }
}
