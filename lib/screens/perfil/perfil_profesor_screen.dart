import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilProfesorScreen extends StatelessWidget {
  const PerfilProfesorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // CAMBIO: AppBar eliminado, ahora está en home_screen.dart
      // appBar: AppBar( ... ),

      // CAMBIO: Usamos un LayoutBuilder para centrar el contenido
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
                              // 1. Icono de Profesor
                              Center(
                                child: CircleAvatar(
                                  radius: 60,
                                  // CAMBIO: Color naranja
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  child: const Icon(
                                    Icons.school,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Título de Bienvenida
                              Text(
                                'Bienvenido, Profesor',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  // CAMBIO: Color naranja oscuro
                                  color: Colors.orange[800],
                                ),
                              ),
                              Text(
                                userEmail,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
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
                                        "Correo Institucional",
                                        userEmail,
                                      ),
                                      const Divider(height: 20),
                                      _buildInfoRow(
                                        context,
                                        Icons.badge,
                                        "Rol",
                                        "PROFESOR",
                                      ),
                                      const Divider(height: 20),
                                      _buildInfoRow(
                                        context,
                                        Icons.calendar_today,
                                        "Miembro Desde",
                                        registrationDate,
                                      ),
                                      const Divider(height: 20),
                                      _buildInfoRow(
                                        context,
                                        Icons.assignment,
                                        "Proyectos Creados",
                                        "0",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // 4. Herramientas
                              Text(
                                'Herramientas del Profesor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800], // CAMBIO
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.assignment_add),
                                label: const Text('Crear Nuevo Proyecto'),
                                onPressed: () => _createProject(context),
                                // CAMBIO: Estilo ya tomado del ThemeData
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.people),
                                label: const Text('Gestionar Estudiantes'),
                                onPressed: () => _manageStudents(context),
                                // CAMBIO: Estilo naranja
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  side: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.bar_chart),
                                label: const Text('Ver Estadísticas'),
                                onPressed: () => _showStatistics(context),
                                // CAMBIO: Estilo naranja
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  side: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
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

  // --- Lógica de botones (sin cambios) ---
  void _createProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Nuevo Proyecto'),
          content: const Text(
            '¿Deseas crear un nuevo proyecto de investigación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Función de creación de proyectos (próximamente)',
                    ),
                  ),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _manageStudents(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panel de gestión de estudiantes (próximamente)'),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estadísticas y reportes (próximamente)')),
    );
  }
}
