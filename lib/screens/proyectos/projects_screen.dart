import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// --- PASO 1: IMPORTAR LA NUEVA PANTALLA ---
import 'package:metro_gestion_proyecto/screens/proyectos/administrar_proyecto_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final String? userRole;

  const ProjectsScreen({super.key, this.userRole});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _expandedProjectId;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Proyectos')),
      body: _buildProjectList(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (widget.userRole == 'profesor') {
      return FloatingActionButton(
        onPressed: _showCrearProyectoDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  Widget _buildProjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No tienes proyectos asignados.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final projects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _buildProjectCard(project);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(DocumentSnapshot project) {
    final projectId = project.id;
    final bool isExpanded = _expandedProjectId == projectId;
    final data = project.data() as Map<String, dynamic>;

    final String nombre = data.containsKey('nombre')
        ? data['nombre']
        : 'Sin Nombre';
    final String descripcion = data.containsKey('descripcion')
        ? data['descripcion']
        : 'Sin Descripción';
    final List<dynamic> miembros = data.containsKey('miembros')
        ? data['miembros']
        : [];

    final Timestamp? fechaEntregaTimestamp = data.containsKey('fechaEntrega')
        ? data['fechaEntrega']
        : null;
    final DateTime? fechaEntrega = fechaEntregaTimestamp?.toDate();
    final String fechaFormateada = fechaEntrega != null
        ? DateFormat('dd/MM/yyyy').format(fechaEntrega)
        : 'No definida';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProjectId = null;
                } else {
                  _expandedProjectId = projectId;
                }
              });
            },
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  _buildDetailRow('Descripción Completa:', descripcion),
                  const SizedBox(height: 8),
                  _buildDetailRow('Nº de Integrantes:', '${miembros.length}'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Fecha de Entrega:', fechaFormateada),
                  const SizedBox(height: 12),

                  const Text(
                    'Progreso:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 16),

                  if (widget.userRole == 'profesor')
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        // --- PASO 2: ACTUALIZAR EL onPressed ---
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdministrarProyectoScreen(
                                projectId: project.id,
                                projectData:
                                    data, // Pasamos los datos del proyecto
                              ),
                            ),
                          );
                        },
                        child: const Text('Administrar'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  void _showCrearProyectoDialog() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController fechaController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear Nuevo Proyecto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Proyecto',
                      ),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextField(
                      controller: fechaController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Entrega',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setStateDialog(() {
                            selectedDate = picked;
                            fechaController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Crear'),
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
      ).showSnackBar(SnackBar(content: Text('Error al crear el proyecto: $e')));
    }
  }
}
