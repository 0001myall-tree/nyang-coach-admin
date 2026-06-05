import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NyangAdminApp());
}

class NyangAdminApp extends StatelessWidget {
  const NyangAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냥냥코치 어드민',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5EA8)),
        textTheme: GoogleFonts.notoSansKrTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
