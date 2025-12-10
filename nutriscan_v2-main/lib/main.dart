import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/product_details_added_screen.dart';

// Constantes de design (alignées avec BarcodeScannerScreen)
const Color primaryColor = Color(0xFF00C853);
const Color primaryDarkColor = Color(0xFF009624);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF212121);
const Color secondaryTextColor = Color(0xFF757575);

// Constantes pour le mode sombre
const Color darkBackgroundColor = Color(0xFF121212);
const Color darkCardColor = Color(0xFF1E1E1E);
const Color darkTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Firebase.initializeApp();
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
        runApp(MyApp());
      } catch (e) {
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Failed to initialize Firebase: $e')),
            ),
          ),
        );
      }
    },
    (error, stackTrace) {
      print('Top-level error: $error');
      print('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
      _saveTheme(isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/reset': (context) => ResetPasswordScreen(),
        '/scanner': (context) => BarcodeScannerScreen(),
        '/product': (context) => ProductDetailsScreen(),
        '/product_added': (context) => ProductDetailsAddedScreen(),
        '/settings':
            (context) => SettingsScreen(
              isDarkMode: _isDarkMode,
              toggleTheme: toggleTheme,
            ),
      },
      title: 'Product Scanner',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textColor),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
        iconTheme: IconThemeData(color: primaryDarkColor),
        appBarTheme: AppBarTheme(
          backgroundColor: cardColor,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryDarkColor,
          ),
          iconTheme: IconThemeData(color: primaryDarkColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkBackgroundColor,
        cardColor: darkCardColor,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: darkTextColor),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: darkSecondaryTextColor,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
        appBarTheme: AppBarTheme(
          backgroundColor: darkCardColor,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          iconTheme: IconThemeData(color: primaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Color(0xFF2A2A2A),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return BarcodeScannerScreen();
        }
        return LoginScreen();
      },
    );
  }
}
