import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/game_store.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameStore(),
      child: const GridloqApp(),
    ),
  );
}

class GridloqApp extends StatelessWidget {
  const GridloqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gridloq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
      ),
      home: const HomeScreen(),
    );
  }
}
