import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/wallet.dart';
import 'screens/login_screen.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const GameBaaziApp(),
    ),
  );
}

class GameBaaziApp extends StatelessWidget {
  const GameBaaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameBaazi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: AppColors.textLight, displayColor: AppColors.textLight),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
