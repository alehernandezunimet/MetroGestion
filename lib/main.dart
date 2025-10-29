import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metro_gestion_proyecto/firebase_options.dart';
import 'package:metro_gestion_proyecto/screens/home/homepage_screen.dart'; // Nueva importación

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: Colors.orange),
        useMaterial3: true,
      ),
      // MODIFICACIÓN: Ahora la HomePage es la pantalla inicial
      home: const HomePageScreen(),
    );
  }
}