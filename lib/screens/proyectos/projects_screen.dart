import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/administrar_proyecto_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/student_project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final String? userRole;

  const ProjectsScreen({super.key, this.userRole});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _getProjectsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    if (widget.userRole == 'profesor') {
      return _firestore
          .collection('proyectos')
          .where('liderProyecto', isEqualTo: user.uid)
          .where('estado', isEqualTo: 'activo')
          .snapshots();
    } else {
      return _firestore
          .collection('proyectos')
          .where('miembros', arrayContains: user.uid)
          .where('estado', isEqualTo: 'activo')
          .snapshots();
    }
  }

  // --- Construye el contenido del panel desplegable del proyecto ---
  Widget _buildProjectExpansionContent(BuildContext context, String projectId, Map<String, dynamic> projectData) {
    final bool isProfessor = widget.userRole == 'profesor';

    // El mini-dashboard de hitos es visible para ambos roles.
    final hitoDashboard = StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('proyectos')
          .doc(projectId)
          .collection('hitos')
          .orderBy('fechaCreacion')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No hay hitos definidos para este proyecto.')),
          );
        }

        final hitos = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: hitos.map((hitoDoc) {
              final hitoData = hitoDoc.data() as Map<String, dynamic>;
              return StreamBuilder<QuerySnapshot>(
                stream: hitoDoc.reference.collection('tareas').snapshots(),
                builder: (context, tasksSnapshot) {
                  if (!tasksSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final tasks = tasksSnapshot.data!.docs;
                  final totalTasks = tasks.length;
                  final completedTasks = tasks.where((t) => (t.data() as Map<String, dynamic>)['estado'] == 'completada').length;
                  final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
                  final progressPercent = (progress * 100).toStringAsFixed(0);

                  return SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 45.0,
                          lineWidth: 8.0,
                          percent: progress,
                          center: Text(
                            '$progressPercent%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          progressColor: Colors.green,
                          backgroundColor: Colors.grey[300]!,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hitoData['nombre'] ?? 'Hito',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );

    // Si es estudiante, añadimos el botón "Ver Proyecto" debajo del dashboard.
    if (!isProfessor) {
      return Column(
        children: [
          hitoDashboard,
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProjectDetailScreen(
                      projectId: projectId,
                      projectData: projectData,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver Detalles y Entregar Tareas'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      );
    }

    // Si es profesor, solo mostramos el dashboard.
    return hitoDashboard;
  }

  // --- MÉTODOS EXISTENTES PARA CREACIÓN DE PROYECTO (Reconstruidos del snippet) ---
  void _showCreateProjectDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime? selectedDate;
    final fechaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Nuevo Proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Proyecto',
                  ),
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: fechaController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha Límite (Opcional)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                            fechaController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('CREAR'),
              onPressed: () {
                _crearProyecto(
                  nombreController.text,
                  descripcionController.text,
                  selectedDate,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _crearProyecto(
    String nombre,
    String descripcion,
    DateTime? fechaEntrega,
  ) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    if (nombre.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre y la descripción no pueden estar vacíos.'),
        ),
      );
      return;
    }

    try {
      await _firestore.collection('proyectos').add({
        'nombre': nombre,
        'descripcion': descripcion,
        'liderProyecto': user.uid,
        'miembros': [],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'estado': 'activo',
        'fechaEntrega': fechaEntrega != null
            ? Timestamp.fromDate(fechaEntrega)
            : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto creado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear proyecto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfessor = widget.userRole == 'profesor';

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Proyectos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getProjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bool hasProjects = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final projects = hasProjects ? snapshot.data!.docs : [];

          return Column(
            children: [
              Expanded(
                child: hasProjects
                    ? ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final DocumentSnapshot doc = projects[index];
                          final String projectId = doc.id;
                          final Map<String, dynamic> data =
                              doc.data()! as Map<String, dynamic>;
                          final String name =
                              data['nombre'] ?? 'Proyecto sin nombre';
                          final Timestamp? fechaEntrega = data['fechaEntrega'];
                          final String deadline = fechaEntrega != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(fechaEntrega.toDate())
                              : 'Sin límite';

                          final int memberCount =
                              (data['miembros'] as List? ?? []).length;

                          final int materialCount =
                              (data['materiales'] as List? ?? []).length;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entrega: $deadline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Miembros: $memberCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Materiales: $materialCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                                child: const Icon(Icons.folder,
                                    color: Colors.white),
                              ),
                              trailing: isProfessor
                                  ? IconButton(
                                      icon: const Icon(Icons.settings),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdministrarProyectoScreen(
                                              projectId: projectId,
                                              projectData: data,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                              children: [
                                _buildProjectExpansionContent(context, projectId, data),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          isProfessor
                              ? 'No has creado proyectos. ¡Crea uno ahora!'
                              : 'No estás asignado a ningún proyecto.',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),

              // Botón para crear proyecto (Solo para Profesores)
              if (isProfessor)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _showCreateProjectDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('CREAR NUEVO PROYECTO'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
