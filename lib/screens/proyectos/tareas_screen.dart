import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const TasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // No fechas pasadas
      lastDate: DateTime(2030),
      helpText: 'SELECCIONAR FECHA LÍMITE',
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

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Nueva Tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: descriptionController,
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
                                ? 'Fecha Límite: No seleccionada'
                                : 'Fecha Límite: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
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
                  child: const Text('CREAR TAREA'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      _addTask(
                        titleController.text.trim(),
                        descriptionController.text.trim(),
                        selectedDate,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El título no puede estar vacío.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addTask(
    String title,
    String description,
    DateTime? deadline,
  ) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('tareas')
          .add({
            'titulo': title,
            'descripcion': description,
            'fechaCreacion': FieldValue.serverTimestamp(),
            'fechaLimite': deadline != null
                ? Timestamp.fromDate(deadline)
                : null,
            'estado': 'pendiente',
            'asignadoA': [],
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarea creada con éxito.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear tarea: $e')));
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('tareas')
          .doc(taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea eliminada con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar tarea: $e')));
    }
  }

  void _confirmDeleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(taskId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tareas: ${widget.projectName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('proyectos')
                  .doc(widget.projectId)
                  .collection('tareas')
                  .orderBy('fechaCreacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay tareas asignadas para este proyecto.'),
                  );
                }

                final tareas = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                  itemCount: tareas.length,
                  itemBuilder: (context, index) {
                    final tareaDoc = tareas[index];
                    final data = tareaDoc.data() as Map<String, dynamic>;
                    final Timestamp? fechaLimiteTimestamp = data['fechaLimite'];
                    final String fechaLimite = fechaLimiteTimestamp != null
                        ? DateFormat(
                            'dd MMM yyyy',
                          ).format(fechaLimiteTimestamp.toDate())
                        : 'No definida';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                          top: 4,
                          bottom: 4,
                        ),
                        title: Text(
                          data['titulo'] ?? 'Sin título',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Fecha Límite: $fechaLimite',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDeleteTask(context, tareaDoc.id),
                        ),
                        children: <Widget>[
                          const Divider(height: 1, thickness: 1),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 16.0,
                              top: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Descripción:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['descripcion'] ??
                                      'Sin descripción detallada.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. BOTÓN PARA AÑADIR TAREA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add_box),
              label: const Text('AÑADIR NUEVA TAREA'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
