import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/accueil_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final themeSauvegarde = prefs.getString('theme');
  ThemeMode modeInitial;
  switch (themeSauvegarde) {
    case 'clair':
      modeInitial = ThemeMode.light;
      break;
    case 'sombre':
      modeInitial = ThemeMode.dark;
      break;
    default:
      modeInitial = ThemeMode.system;
  }
  runApp(MonApp(modeInitial: modeInitial));
}

class MonApp extends StatefulWidget {
  final ThemeMode modeInitial;
  const MonApp({super.key, required this.modeInitial});

  @override
  State<MonApp> createState() => _MonAppState();
}

class _MonAppState extends State<MonApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.modeInitial;
  }

  Future<void> _changerTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    final valeur = mode == ThemeMode.light
        ? 'clair'
        : mode == ThemeMode.dark
            ? 'sombre'
            : 'systeme';
    await prefs.setString('theme', valeur);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHome Connect',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // StreamBuilder écoute l'état de connexion en temps réel
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Connecté → accueil
          if (snapshot.hasData) {
            return AccueilScreen(
              onChangerTheme: _changerTheme,
              themeMode: _themeMode,
            );
          }
          // Non connecté → écran de connexion
          return const AuthScreen();
        },
      ),
    );
  }
}