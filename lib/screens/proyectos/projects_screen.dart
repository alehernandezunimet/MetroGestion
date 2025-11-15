import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/administrar_proyecto_screen.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/tareas_screen.dart'; // Importación necesaria

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

  // --- FUNCIÓN AÑADIDA: Maneja la actualización del estado de la tarea ---
  Future<void> _toggleTaskCompletion(
    String projectId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(projectId)
          .collection('tareas')
          .doc(taskId)
          .update({'estado': isCompleted ? 'completada' : 'pendiente'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarea ${isCompleted ? 'completada' : 'marcada como pendiente'} con éxito.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar tarea: $e')));
    }
  }

  // --- FUNCIÓN AÑADIDA: Construye la lista de tareas con el Checkbox ---
  Widget _buildTasksList(String projectId) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('No hay usuario autenticado.'));
    }

    final bool isProfessor = widget.userRole == 'profesor';

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('proyectos')
          .doc(projectId)
          .collection('tareas')
          .orderBy('fechaLimite', descending: false)
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
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar tareas: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay tareas para este proyecto.'),
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tasks.map((doc) {
            final taskId = doc.id;
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['nombre'] ?? 'Tarea sin nombre';
            final String estado = data['estado'] ?? 'pendiente';
            final bool isCompleted = estado == 'completada';
            final List<dynamic> assignedTo = data['asignadoA'] ?? [];
            final Timestamp? deadlineTimestamp = data['fechaLimite'];
            final String deadline = deadlineTimestamp != null
                ? DateFormat('dd/MM/yyyy').format(deadlineTimestamp.toDate())
                : 'Sin límite';

            // FILTRO PARA ESTUDIANTES: Solo muestra tareas asignadas a él.
            if (!isProfessor &&
                assignedTo.isNotEmpty &&
                !assignedTo.contains(user.uid)) {
              return Container();
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isCompleted ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Límite: $deadline',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Estado: ${estado.toUpperCase()}',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Checkbox solo visible para estudiantes
                trailing: !isProfessor
                    ? Checkbox(
                        value: isCompleted,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            // Llamada a la función para actualizar Firestore
                            _toggleTaskCompletion(projectId, taskId, newValue);
                          }
                        },
                        activeColor: Colors.green,
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
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
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No hay proyectos asignados o creados.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (isProfessor)
                    const Text(
                      '¡Crea uno ahora!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            );
          }

          final projects = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot doc = projects[index];
                    final String projectId = doc.id;
                    final Map<String, dynamic> data =
                        doc.data()! as Map<String, dynamic>;
                    final String name = data['nombre'] ?? 'Proyecto sin nombre';
                    // La descripción y la fecha no se usan directamente en el título, pero se mantienen.
                    // final String description = data['descripcion'] ?? 'Sin descripción';
                    final Timestamp? fechaEntrega = data['fechaEntrega'];
                    final String deadline = fechaEntrega != null
                        ? DateFormat('dd/MM/yyyy').format(fechaEntrega.toDate())
                        : 'Sin límite';

                    final int memberCount =
                        (data['miembros'] as List? ?? []).length;

                    // --- INICIO DEL CARD DE PROYECTO CON DESPLEGABLE ---
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.folder, color: Colors.white),
                        ),
                        // Botón de administración (Solo para profesores)
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
                            : null, // Los estudiantes no tienen botón de gestión
                        // Contenido del Desplegable (Lista de Tareas)
                        // LLAMADA A LA FUNCIÓN CON EL CHECKBOX
                        children: [
                          _buildTasksList(projectId),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                    // --- FIN DEL CARD DE PROYECTO CON DESPLEGABLE ---
                  },
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
