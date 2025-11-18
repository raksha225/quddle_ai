import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quddle_ai_frontend/utils/theme/theme.dart';
import 'package:quddle_ai_frontend/utils/routes.dart';
import 'package:quddle_ai_frontend/bloc/Profile/profile_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quddle',
        theme: MyTheme.myTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
