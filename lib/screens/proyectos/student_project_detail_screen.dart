import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/task_submission_screen.dart';

class StudentProjectDetailScreen extends StatelessWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const StudentProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  Widget build(BuildContext context) {
    final String projectName = projectData['nombre'] ?? 'Detalles del Proyecto';
    final String projectDescription = projectData['descripcion'] ?? 'Sin descripción.';
    final Timestamp? deadline = projectData['fechaEntrega'];

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sección de Detalles del Proyecto ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción del Proyecto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (deadline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Fecha límite: ${DateFormat('dd/MM/yyyy').format(deadline.toDate())}',
                          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    const Divider(height: 24),
                    Text(projectDescription),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Sección de Hitos y Tareas ---
            const Text(
              'Hitos y Tareas Asignadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildHitosList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHitosList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proyectos')
          .doc(projectId)
          .collection('hitos')
          .orderBy('fechaCreacion')
          .snapshots(),
      builder: (context, hitosSnapshot) {
        if (hitosSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!hitosSnapshot.hasData || hitosSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Este proyecto aún no tiene hitos.'));
        }

        final hitos = hitosSnapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hitos.length,
          itemBuilder: (context, index) {
            final hitoDoc = hitos[index];
            final hitoData = hitoDoc.data() as Map<String, dynamic>;
            final hitoName = hitoData['nombre'] ?? 'Hito sin nombre';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                leading: Icon(Icons.flag_outlined, color: Theme.of(context).primaryColor),
                title: Text(hitoName, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: hitoDoc.reference.collection('tareas').snapshots(),
                    builder: (context, tasksSnapshot) {
                      if (!tasksSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (tasksSnapshot.data!.docs.isEmpty) {
                        return const ListTile(title: Text('No hay tareas en este hito.'));
                      }

                      final tasks = tasksSnapshot.data!.docs;
                      return Column(
                        children: tasks.map((taskDoc) {
                          final taskData = taskDoc.data() as Map<String, dynamic>;
                          final bool isCompleted = taskData['estado'] == 'completada';

                          return ListTile(
                            title: Text(taskData['nombre'] ?? 'Tarea'),
                            subtitle: Text(
                              isCompleted ? 'Entregada' : 'Pendiente',
                              style: TextStyle(
                                color: isCompleted ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskSubmissionScreen(
                                    projectId: projectId,
                                    hitoId: hitoDoc.id,
                                    taskId: taskDoc.id,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}