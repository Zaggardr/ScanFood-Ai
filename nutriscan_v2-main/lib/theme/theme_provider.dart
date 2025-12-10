import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Constantes de design
const Color primaryColor = Color(0xFF00C853);
const Color errorColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF212121);
const Color secondaryTextColor = Color(0xFF757575);
const Color darkBackgroundColor = Color(0xFF121212);
const Color darkCardColor = Color(0xFF1E1E1E);
const Color darkTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const double cardElevation = 4.0;
const double cardBorderRadius = 12.0;
const double buttonBorderRadius = 8.0;
const double defaultPadding = 16.0;
const double itemSpacing = 12.0;

// Styles de texte communs
final TextStyle headlineStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(fontSize: 14);

final TextStyle captionStyle = GoogleFonts.poppins(fontSize: 12);

final TextStyle buttonStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  final lightTheme = ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    primaryColor: primaryColor,
    textTheme: TextTheme(bodySmall: TextStyle(color: textColor)),
    appBarTheme: AppBarTheme(
      backgroundColor: cardColor,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textColor),
    ),
    iconTheme: IconThemeData(color: textColor),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[100],
      filled: true,
    ),
    dividerColor: secondaryTextColor,
  );

  final darkTheme = ThemeData(
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    primaryColor: primaryColor,
    textTheme: TextTheme(bodySmall: TextStyle(color: darkTextColor)),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCardColor,
      titleTextStyle: TextStyle(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: darkTextColor),
    ),
    iconTheme: IconThemeData(color: darkTextColor),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[900],
      filled: true,
    ),
    dividerColor: darkSecondaryTextColor,
  );
}
