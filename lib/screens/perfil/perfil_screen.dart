import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Ancho máximo
              child: user == null
                  ? const Center(child: Text("No hay usuario autenticado"))
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          // CAMBIO: Indicador naranja
                          return Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error al cargar el perfil"),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;

                        final userEmail = user.email ?? 'No disponible';
                        final userRole = data?['rol'] ?? 'Estudiante';
                        final registrationDate = data?['fechaRegistro'] != null
                            ? (data!['fechaRegistro'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .substring(0, 10)
                            : '---';

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // 1. Icono de Usuario
                              Center(
                                child: CircleAvatar(
                                  radius: 60,
                                  // CAMBIO: Color naranja
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  child: const Icon(
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
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  // CAMBIO: Color naranja oscuro
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // 3. Información
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        context,
                                        Icons.email,
                                        "Correo",
                                        userEmail,
                                      ),
                                      const Divider(height: 20),
                                      _buildInfoRow(
                                        context,
                                        Icons.badge,
                                        "Rol",
                                        userRole.toUpperCase(),
                                      ),
                                      const Divider(height: 20),
                                      _buildInfoRow(
                                        context,
                                        Icons.calendar_today,
                                        "Miembro Desde",
                                        registrationDate,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // CAMBIO: Botón de Proyectos eliminado
                              // (Ahora está en el menú lateral de home_screen)
                            ],
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para las filas de información
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        // CAMBIO: Icono naranja
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }
}
