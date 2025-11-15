import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/administrar_proyecto_screen.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/tareas_screen.dart'; // Asegúrate de que TasksScreen esté disponible

class ProjectsScreen extends StatefulWidget {
  final String? userRole;

  const ProjectsScreen({super.key, this.userRole});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ya no necesitamos _expandedProjectId si usamos ExpansionTile directamente

  Stream<QuerySnapshot> _getProjectsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Si es profesor, muestra los proyectos que lidera.
    if (widget.userRole == 'profesor') {
      return _firestore
          .collection('proyectos')
          .where('liderProyecto', isEqualTo: user.uid)
          .where('estado', isEqualTo: 'activo')
          .snapshots();
    } else {
      // Si es estudiante, muestra los proyectos en los que es miembro.
      return _firestore
          .collection('proyectos')
          .where('miembros', arrayContains: user.uid)
          .where('estado', isEqualTo: 'activo')
          .snapshots();
    }
  }

  // --- NUEVA FUNCIÓN PARA LISTAR TAREAS DENTRO DEL DESPLEGABLE ---
  Widget _buildTasksList(String projectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('proyectos')
          .doc(projectId)
          .collection('tareas')
          .orderBy('fechaLimite') // Ordenar por fecha límite
          .snapshots(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final tasks = taskSnapshot.data?.docs ?? [];

        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text('No hay tareas asignadas a este proyecto.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Tareas Asignadas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            ...tasks.map((taskDoc) {
              final taskData = taskDoc.data() as Map<String, dynamic>;
              final Timestamp? fechaLimiteTimestamp = taskData['fechaLimite'];
              final String fechaLimite = fechaLimiteTimestamp != null
                  ? DateFormat(
                      'dd MMM yyyy',
                    ).format(fechaLimiteTimestamp.toDate())
                  : 'Sin Fecha Límite';

              // Mostrar título, descripción y fecha límite
              return ListTile(
                dense: true,
                leading: Icon(Icons.assignment, color: Colors.orange[700]),
                title: Text(
                  taskData['titulo'] ?? 'Tarea sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskData['descripcion'] ?? 'Sin descripción.',
                      maxLines: 2, // Muestra una descripción limitada
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Límite: $fechaLimite',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
  // ---------------------------------------------------------------------

  // (Aquí irían los métodos _selectDate, _showCreateProjectDialog, _crearProyecto si no están ya en el snippet)
  // ... (asumo que están más arriba o son correctos)

  // (Mantenemos la función _crearProyecto aquí)
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

  // (Mantenemos la función _showCreateProjectDialog aquí)
  void _showCreateProjectDialog() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    DateTime? selectedDate;

    // Helper para seleccionar la fecha (copiado de TasksScreen para completar)
    Future<DateTime?> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
        helpText: 'SELECCIONAR FECHA DE ENTREGA',
        cancelText: 'CANCELAR',
        confirmText: 'CONFIRMAR',
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );
      return picked;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Crear Nuevo Proyecto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Proyecto',
                      ),
                    ),
                    TextFormField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Fecha de Entrega: No seleccionada'
                                : 'Fecha de Entrega: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('SELECCIONAR'),
                          onPressed: () async {
                            final DateTime? picked = await _selectDate(context);
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCELAR'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('CREAR PROYECTO'),
                  onPressed: () {
                    if (nombreController.text.isEmpty ||
                        descripcionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El nombre y la descripción son requeridos.',
                          ),
                        ),
                      );
                      return;
                    }
                    _crearProyecto(
                      nombreController.text.trim(),
                      descripcionController.text.trim(),
                      selectedDate,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfessor = widget.userRole == 'profesor';

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Proyectos'), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getProjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                isProfessor
                    ? 'Aún no has creado ningún proyecto.'
                    : 'Aún no estás asignado a ningún proyecto.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final projects = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final projectDoc = projects[index];
                    final projectId = projectDoc.id;
                    final data = projectDoc.data() as Map<String, dynamic>;

                    // Detalles del proyecto
                    final Timestamp? fechaTimestamp = data['fechaEntrega'];
                    final String fechaEntrega = fechaTimestamp != null
                        ? DateFormat(
                            'dd MMM yyyy',
                          ).format(fechaTimestamp.toDate())
                        : 'No definida';

                    // --- INICIO DEL CARD DE PROYECTO CON DESPLEGABLE DE TAREAS ---
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        // Encabezado del Desplegable (Título y Descripción breve)
                        title: Text(
                          data['nombre'] ?? 'Proyecto sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrega: $fechaEntrega',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['descripcion'] ?? 'Sin descripción.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        // Botón de Gestión (Solo para Profesores)
                        trailing: isProfessor
                            ? IconButton(
                                icon: const Icon(
                                  Icons.manage_accounts,
                                  color: Colors.orange,
                                ),
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
                        children: [_buildTasksList(projectId)],
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
