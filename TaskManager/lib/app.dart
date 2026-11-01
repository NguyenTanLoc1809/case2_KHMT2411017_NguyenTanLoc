import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(isDense: false),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.unknown:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case AuthStatus.authenticated:
              return const HomeScreen();
            case AuthStatus.unauthenticated:
              return const LoginScreen();
          }
        },
      ),
    );
  }
}
