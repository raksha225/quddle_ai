import 'package:flutter/material.dart';

class MyColors {
  MyColors._();

  static const Color primary = Color(0xFF7D017C);
  static const Color navbar = Color(0xFFFEFFFF);
  static const Color whitebox = Color.fromARGB(255, 233, 233, 233);
  static const Color bgscaffold = Color.fromARGB(255, 220, 220, 220);
  // static const Color primary = Color(0xFF265741);

  static const Color secondary = Color(0xFF000000);
  static const Color accent = Color(0xFF3B83F4);

  static const Color textWhite = Colors.white;
  static Color white60 = Colors.white.withOpacity(0.6);
  static const Color softBlack = Color(0xFF9DA5AF);
  static const Color greyColor = Color(0xFFD9D9D9);

  static const Color fadedPrimary = Color(0xFF192438);
  static const Color borderColor = Color.fromRGBO(255, 255, 255, 0.4);
  static const Color presentColor = Color(0xFF60B91F);
  static const Color absentColor = Color(0xFFFF5A5A);

  static Color fadedPresentColor = const Color(0xFF60B91F).withOpacity(0.32);
  static Color fadedAbsentColor = const Color(0xFFFF5A5A).withOpacity(0.32);

  static const Color dColor = Color(0xFF60B91F);
  static const Color sColor = Color(0xFF3B83F4);
  static const Color weightColor = Color(0xFF138d75);
  static const Color hrColor = Color(0xFFFF6B6B);

  static const Color otherColor = Color(0xFF3B83F4);
  static const Color myColor = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color bgColor = Color(0xFFF8FBFA);
  static const Color advertisterNavbar = Color.fromARGB(255, 106, 0, 187);

    static const int _primaryValue = 0xFF7D017C;

static const MaterialColor newPrimary = MaterialColor(
  _primaryValue,
  <int, Color>{
    50: Color(0xFFF8E6F8),
    100: Color(0xFFEFBFEE),
    200: Color(0xFFE495E3),
    300: Color(0xFFD96BD9),
    400: Color(0xFFD04CD0),
    500: Color(_primaryValue),
    600: Color(0xFF6C0070),
    700: Color(0xFF5D0061),
    800: Color(0xFF4A004D),
    900: Color(0xFF320033),
  },
);

/// 🌈 Deep magenta–purple gradient for Quddle-style design
static const LinearGradient navbarGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF8B008B), // Dark magenta (top)
    Color(0xFFDA1D81), // Vivid pinkish-purple (bottom)
  ],
);

/// (Optional) Use this for buttons or cards to match theme
static const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF8B008B),
    Color(0xFFDA1D81),
  ],
);

}
