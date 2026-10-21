import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/case_store.dart';
import 'screens/home_screen.dart';
import 'screens/housecode_screen.dart';
import 'services/auth_service.dart';
import 'services/household_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.ensureSignedIn();
  runApp(const FridgeCourtApp());
}

class FridgeCourtApp extends StatelessWidget {
  const FridgeCourtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Court',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const _StartupGate(),
    );
  }
}

/// Decides, once per app start, whether this device already belongs to a
/// household (saved locally) or needs to go through the housecode screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: HouseholdService.instance.getSavedMembership(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final membership = snapshot.data;
        if (membership == null) {
          return const HousecodeScreen();
        }

        return HomeScreen(
          store: CaseStore(
            householdCode: membership.code,
            displayName: membership.name,
          ),
        );
      },
    );
  }
}