import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart';
import 'package:metro_gestion_proyecto/screens/perfil/perfil_screen.dart';
import 'package:metro_gestion_proyecto/screens/perfil/profesor_screen.dart';

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
              'Inicio de Sesión Exitoso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),


            if (user != null)
              Text(
                'Bienvenido, ${user.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 40),


            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data?.data() == null) {

                  return _buildProfileButton(
                    context: context,
                    isProfessor: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final userRole = data['rol'] ?? 'estudiante';
                final isProfessor = userRole == 'profesor';

                return _buildProfileButton(
                  context: context,
                  isProfessor: isProfessor,
                  onPressed: () {
                    if (isProfessor) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfesorScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 20),


            ElevatedButton.icon(
              icon: const Icon(Icons.assignment, color: Colors.white),
              label: const Text('Ver Proyectos'),
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navegando a proyectos...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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