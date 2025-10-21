import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metro_gestion_proyecto/firebase_options.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'METROGESTIÓN',
      theme: ThemeData(
        // Define el tema de tu aplicación basado en tu logo (azul y naranja)
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.orange),
        useMaterial3: true,
      ),
      // 3. MODIFICACIÓN: El punto de inicio de la app es el LoginScreen
      home: const LoginScreen(),
    );
  }