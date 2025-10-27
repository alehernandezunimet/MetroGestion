import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart'; // Para navegar de vuelta
import 'package:metro_gestion_proyecto/screens/perfil/perfil_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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

            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),


            const Text(
              '¡Inicio de Sesión Exitoso! Bienvenido.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20), // Espacio entre texto y botón
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: const Text("Ver Perfil"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required BuildContext context,
    required bool isProfessor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(
        isProfessor ? Icons.school : Icons.person,
        color: Colors.white,
      ),
      label: Text(isProfessor ? "Panel del Profesor" : "Mi Perfil"),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isProfessor ? Colors.deepPurple : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}