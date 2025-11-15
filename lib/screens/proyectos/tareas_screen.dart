import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  DateTime? _selectedDeadline;

  String? _currentUserRole;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        _currentUserRole = userDoc.data()?['rol'];
      }
    }
    setState(() {
      _isLoadingUser = false;
    });
  }

  Future<void> _toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('tareas')
          .doc(taskId)
          .update({
            'estado': isCompleted ? 'completada' : 'pendiente',
            'fechaCompletada': isCompleted
                ? FieldValue.serverTimestamp()
                : null,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? 'Tarea marcada como completada. 🎉'
                : 'Tarea marcada como pendiente. ⏳',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar tarea: $e')));
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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

  Future<void> _createTask(
    String name,
    String description,
    DateTime? deadline,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la tarea no puede estar vacío.'),
        ),
      );
      return;
    }

    try {
      await _firestore
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('tareas')
          .add({
            'nombre': name,
            'descripcion': description,
            'liderProyectoId': _auth.currentUser?.uid,
            'fechaCreacion': FieldValue.serverTimestamp(),
            'fechaLimite': deadline != null
                ? Timestamp.fromDate(deadline)
                : null,
            'estado': 'pendiente',
            'asignadoA': [],
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarea creada con éxito.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear tarea: $e')));
    }
  }

  void _showAddTaskDialog() {
    _nombreController.clear();
    _descripcionController.clear();
    _selectedDeadline = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir Nueva Tarea'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Tarea',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el nombre de la tarea';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setInnerState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDeadline == null
                                ? 'Fecha Límite: No establecida'
                                : 'Fecha Límite: ${DateFormat('dd/MM/yyyy').format(_selectedDeadline!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final pickedDate = await _selectDate(context);
                              if (pickedDate != null) {
                                setInnerState(() {
                                  _selectedDeadline = pickedDate;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Seleccionar Fecha Límite'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Crear'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _createTask(
                    _nombreController.text.trim(),
                    _descripcionController.text.trim(),
                    _selectedDeadline,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tareas: ${widget.projectName}'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isProfessor = _currentUserRole == 'profesor';

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
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay tareas para este proyecto.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: snapshot.data!.docs.map((doc) {
                    final task = doc.data() as Map<String, dynamic>;
                    final taskId = doc.id;
                    final String nombre = task['nombre'] ?? 'Sin nombre';
                    final String descripcion =
                        task['descripcion'] ?? 'Sin descripción';
                    final String estado = task['estado'] ?? 'pendiente';
                    final Timestamp? fechaLimite = task['fechaLimite'];

                    final bool isCompleted = estado == 'completada';

                    final String fechaLimiteText = fechaLimite != null
                        ? DateFormat('dd/MM/yyyy').format(fechaLimite.toDate())
                        : 'No definida';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        title: Text(
                          nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isCompleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              descripcion,
                              style: TextStyle(
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                fontStyle: isCompleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Límite: $fechaLimiteText',
                              style: TextStyle(
                                color: isCompleted ? Colors.grey : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Estado: ${estado == 'completada' ? 'Completada' : 'Pendiente'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.orange,
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
                                    _toggleTaskCompletion(taskId, newValue);
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
            ),
          ),

          if (isProfessor)
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
