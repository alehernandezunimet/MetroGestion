import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/projects_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("No hay usuario autenticado"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error al cargar el perfil"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                final userEmail = user.email ?? 'No disponible';
                final userRole = data?['rol'] ?? 'Estudiante';
                final registrationDate = data?['fechaRegistro'] != null
                    ? (data!['fechaRegistro'] as Timestamp)
                          .toDate()
                          .toString()
                          .substring(0, 10)
                    : '---';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // 1. Icono de Usuario
                      const Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Título de Bienvenida
                      Text(
                        '¡Hola, $userEmail!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Información de cada perfil
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                Icons.email,
                                "Correo Electrónico",
                                userEmail,
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(
                                Icons.school,
                                "Rol",
                                userRole.toUpperCase(),
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(
                                Icons.calendar_today,
                                "Miembro Desde",
                                registrationDate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 4. Botones de Acción (Orientados a Estudiante)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Ver proyectos activos'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProjectsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Configuración de Notificaciones'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Función de notificaciones (próximamente)',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Widget auxiliar para las filas de información
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
