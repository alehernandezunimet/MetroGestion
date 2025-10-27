import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/projects_screen.dart';

class PerfilProfesorScreen extends StatelessWidget {
  const PerfilProfesorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel del Profesor"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {

              _showProfessorSettings(context);
            },
          ),
        ],
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
          final userRole = data?['rol'] ?? 'Profesor';
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
                // 1. Icono de Profesor
                const Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.school,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                Text(
                  'Bienvenido, Profesor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
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
                          "Correo Institucional",
                          userEmail,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.badge,
                          "Rol",
                          "PROFESOR",
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Miembro Desde",
                          registrationDate,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.assignment,
                          "Proyectos Creados",
                          "0 proyectos",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),


                const Text(
                  'Herramientas del Profesor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),


                ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_add, color: Colors.white),
                  label: const Text('Crear Nuevo Proyecto'),
                  onPressed: () {
                    _createNewProject(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),


                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt, color: Colors.white),
                  label: const Text('Gestionar Proyectos Existentes'),
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


                ElevatedButton.icon(
                  icon: const Icon(Icons.people, color: Colors.white),
                  label: const Text('Gestionar Estudiantes'),
                  onPressed: () {
                    _manageStudents(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),


                OutlinedButton.icon(
                  icon: const Icon(Icons.analytics, color: Colors.orange),
                  label: const Text('Ver Estadisticas', style: TextStyle(color: Colors.orange)),
                  onPressed: () {
                    _showStatistics(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
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


  void _createNewProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Nuevo Proyecto'),
          content: const Text('¿Deseas crear un nuevo proyecto de investigación?'),
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
                    content: Text('Función de creación de proyectos (próximamente)'),
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
      const SnackBar(
        content: Text('Estadísticas y reportes (próximamente)'),
      ),
    );
  }

  void _showProfessorSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuraciones del profesor (próximamente)'),
      ),
    );
  }
}