import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart'; // Para navegar de vuelta
import 'package:metro_gestion_proyecto/services/navigation_service.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función para cerrar la sesión
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Inicio de Sesión Exitoso! Bienvenido.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20), // Espacio entre texto y botón
            ElevatedButton(
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                irAlPerfil(context, uid); // 👈 aquí decides a qué perfil ir
              },
              child: const Text("Ver Perfil"),
            ),
          ],
        ),
      ),
      
    );
  }
}
