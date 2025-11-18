
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'text_theme.dart';

class MyTheme {
  MyTheme._();

  static ThemeData myTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      primaryColor: MyColors.navbar,
      scaffoldBackgroundColor: MyColors.bgColor,
      textTheme: MyTextTheme.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: MyColors.navbar,
        elevation: 0.5, // subtle shadow
        shadowColor: MyColors.myColor,
        iconTheme: IconThemeData(
          color: Colors.black,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ));
}
