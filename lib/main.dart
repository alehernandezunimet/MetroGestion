import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metro_gestion_proyecto/firebase_options.dart';
import 'package:metro_gestion_proyecto/screens/home/homepage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'METROGESTIÓN',
      debugShowCheckedModeBanner: false, // CAMBIO: Oculta la cinta de "debug"
      theme: ThemeData(
        // CAMBIO: Tema principal Naranja
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
        ).copyWith(secondary: Colors.orangeAccent),
        useMaterial3: true,

        // CAMBIO: Estilo de AppBar para toda la app
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // CAMBIO: Estilo de botones para toda la app
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange, // Botón naranja
            foregroundColor: Colors.white, // Texto blanco
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomePageScreen(),
    );
  }
}
