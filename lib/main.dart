import 'package:flutter/material.dart';
import 'data/case_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FridgeCourtApp());
}

class FridgeCourtApp extends StatelessWidget {
  const FridgeCourtApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CaseStore();

    return MaterialApp(
      title: 'Fridge Court',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(store: store),
    );
  }
}
