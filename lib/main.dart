import 'package:flutter/material.dart';
import 'telas/tela_login.dart';
import 'regras/app_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Controle de Presença - Grupo Multilixo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.purple,
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF6B2D82),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
          ),
          themeMode: AppController.instance.isDarkTheme
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const TelaLogin(),
        );
      },
    );
  }
}