import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'hitos_screen.dart';
import 'project_progress_dashboard.dart';

class AdministrarProyectoScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const AdministrarProyectoScreen({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<AdministrarProyectoScreen> createState() =>
      _AdministrarProyectoScreenState();
}

class _AdministrarProyectoScreenState extends State<AdministrarProyectoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _descripcionController;
  late TextEditingController _fechaController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Variable para controlar el modo edición
  bool _isEditing = false;

  late List<dynamic> _currentMiembros;
  late List<dynamic> _currentMateriales;

  @override
  void initState() {
    super.initState();

    _descripcionController = TextEditingController(
      text: widget.projectData['descripcion'],
    );

    final Timestamp? fechaTimestamp = widget.projectData['fechaEntrega'];
    if (fechaTimestamp != null) {
      _selectedDate = fechaTimestamp.toDate();
      _fechaController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(_selectedDate!),
      );
    } else {
      _fechaController = TextEditingController();
    }

    _currentMiembros = List<dynamic>.from(widget.projectData['miembros'] ?? []);
    _currentMateriales = List<dynamic>.from(
      widget.projectData['materiales'] ?? [],
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  // --- Lógica para guardar cambios ---
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'descripcion': _descripcionController.text.trim(),
        'fechaEntrega': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto actualizado con éxito.')),
      );

      // Al guardar exitosamente, salimos del modo edición
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el proyecto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- LÓGICA: Mostrar diálogo para AGREGAR estudiante ---
  void _showAgregarEstudianteDialog() {
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar Estudiante'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ingrese el email del estudiante a agregar:'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Ingrese un email válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setStateDialog(() {
                              isAdding = true;
                            });
                            await _procesarAgregarEstudiante(
                              emailController.text.trim(),
                            );
                            setStateDialog(() {
                              isAdding = false;
                            });
                            Navigator.pop(context);
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _procesarAgregarEstudiante(String email) async {
    try {
      final query = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .where('rol', isEqualTo: 'estudiante')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró un estudiante con ese email.'),
          ),
        );
        return;
      }

      final studentDoc = query.docs.first;
      final studentId = studentDoc.id;

      if (_currentMiembros.contains(studentId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este estudiante ya está en el proyecto.'),
          ),
        );
        return;
      }

      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'miembros': FieldValue.arrayUnion([studentId]),
      });

      setState(() {
        _currentMiembros.add(studentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante agregado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar estudiante: $e')),
      );
    }
  }

  void _showEliminarEstudianteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Eliminar Estudiante'),
              content: SizedBox(
                width: double.maxFinite,
                child: _buildMiembrosListDialog(setStateDialog),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMiembrosListDialog(StateSetter setStateDialog) {
    if (_currentMiembros.isEmpty) {
      return const Text('No hay estudiantes en este proyecto.');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMiembrosDetalles(_currentMiembros),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No se encontraron datos de los estudiantes.');
        }

        final miembros = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: miembros.length,
          itemBuilder: (context, index) {
            final miembro = miembros[index];
            return ListTile(
              title: Text(miembro['nombre']),
              subtitle: Text(miembro['email']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _removerMiembro(miembro['uid']);
                  setState(() {
                    _currentMiembros.remove(miembro['uid']);
                  });
                  setStateDialog(() {});
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualizarMiembrosList() {
    if (_currentMiembros.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text(
          'No hay estudiantes asignados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMiembrosDetalles(_currentMiembros),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Error al cargar datos de estudiantes.');
        }

        final miembros = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: miembros.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> miembro = entry.value;

                return Container(
                  color: index.isEven ? Colors.white : Colors.grey[50],
                  child: ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: Colors.blue[700],
                    ),
                    title: Text(miembro['nombre']),
                    subtitle: Text(miembro['email']),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisualizarMaterialesList() {
    if (_currentMateriales.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text(
          'No hay materiales asignados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: _currentMateriales.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> material = Map<String, dynamic>.from(
              entry.value,
            );

            return Container(
              color: index.isEven ? Colors.white : Colors.grey[50],
              child: ListTile(
                leading: Icon(
                  Icons.build_circle_outlined,
                  color: Colors.orange[700],
                ),
                title: Text(material['nombre'] ?? 'Sin nombre'),
                trailing: Text(
                  'Cantidad: ${material['cantidad'] ?? 0}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAgregarMaterialDialog() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController cantidadController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Material'),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del material',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingrese un nombre'
                      : null,
                ),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una cantidad';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final nuevoMaterial = {
                    'nombre': nombreController.text.trim(),
                    'cantidad': int.parse(cantidadController.text.trim()),
                  };
                  _procesarAgregarMaterial(nuevoMaterial);
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarAgregarMaterial(Map<String, dynamic> material) async {
    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'materiales': FieldValue.arrayUnion([material]),
      });

      setState(() {
        _currentMateriales.add(material);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material agregado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agregar material: $e')));
    }
  }

  void _showEliminarMaterialDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Material'),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildMaterialesListDialog(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialesListDialog() {
    if (_currentMateriales.isEmpty) {
      return const Text('No hay materiales para eliminar.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _currentMateriales.length,
      itemBuilder: (context, index) {
        final material = Map<String, dynamic>.from(_currentMateriales[index]);
        return ListTile(
          title: Text(material['nombre']),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _removerMaterial(material);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getMiembrosDetalles(
    List<dynamic> miembrosIds,
  ) async {
    if (miembrosIds.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> miembrosData = [];
    final query = await _firestore
        .collection('usuarios')
        .where(FieldPath.documentId, whereIn: miembrosIds)
        .get();

    for (var doc in query.docs) {
      miembrosData.add({
        'uid': doc.id,
        'nombre': doc.data()['nombre'] ?? 'Sin Nombre',
        'email': doc.data()['email'] ?? 'Sin Email',
      });
    }
    return miembrosData;
  }

  Future<void> _removerMiembro(String studentId) async {
    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'miembros': FieldValue.arrayRemove([studentId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante eliminado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar estudiante: $e')),
      );
    }
  }

  Future<void> _removerMaterial(Map<String, dynamic> material) async {
    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'materiales': FieldValue.arrayRemove([material]),
      });

      setState(() {
        _currentMateriales.remove(material);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material eliminado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar material: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Proyecto')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECCIÓN: DASHBOARD ---
                const Text(
                  'Dashboard de Progreso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('proyectos')
                      .doc(widget.projectId)
                      .collection('hitos')
                      .snapshots(),
                  builder: (context, hitosSnapshot) {
                    if (hitosSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (hitosSnapshot.hasError) {
                      return const Center(
                        child: Text('Error al cargar datos del dashboard.'),
                      );
                    }

                    final hitoDocs = hitosSnapshot.data?.docs ?? [];

                    return FutureBuilder<List<Hito>>(
                      future: Future.wait(
                        hitoDocs.map((hitoDoc) async {
                          final tareasSnapshot = await hitoDoc.reference
                              .collection('tareas')
                              .get();
                          final tasks = tareasSnapshot.docs.map((taskDoc) {
                            final data = taskDoc.data();
                            return Task(
                              id: taskDoc.id,
                              name: data['nombre'] ?? 'Tarea sin nombre',
                              isCompleted: data['estado'] == 'completada',
                            );
                          }).toList();
                          return Hito(
                            id: hitoDoc.id,
                            name: hitoDoc.data()['nombre'] ?? 'Hito sin nombre',
                            tasks: tasks,
                          );
                        }).toList(),
                      ),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final project = Project(
                          id: widget.projectId,
                          name: widget.projectData['nombre'] ?? 'Proyecto',
                          milestones: projectSnapshot.data ?? [],
                        );

                        return ProjectProgressDashboard(project: project);
                      },
                    );
                  },
                ),

                const Divider(height: 40),

                // --- SECCIÓN: DATOS DEL PROYECTO (MODIFICADA) ---
                // Cabecera con Título y Botón Editar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Información General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Solo mostramos el lápiz si NO estamos editando
                    if (!_isEditing)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar información',
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Nombre: ${widget.projectData['nombre']}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Descripción
                TextFormField(
                  controller: _descripcionController,
                  enabled: _isEditing, // Bloqueado si no se edita
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    // Borde normal al editar, sin borde al leer
                    border: _isEditing
                        ? const OutlineInputBorder()
                        : InputBorder.none,
                    // Fondo suave al editar
                    filled: _isEditing,
                    fillColor: _isEditing
                        ? Colors.grey[50]
                        : Colors.transparent,
                    contentPadding: _isEditing
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La descripción no puede estar vacía';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Fecha
                TextFormField(
                  controller: _fechaController,
                  enabled: _isEditing, // Bloqueado si no se edita
                  decoration: InputDecoration(
                    labelText: 'Fecha de Entrega',
                    border: _isEditing
                        ? const OutlineInputBorder()
                        : InputBorder.none,
                    filled: _isEditing,
                    fillColor: _isEditing
                        ? Colors.grey[50]
                        : Colors.transparent,
                    contentPadding: _isEditing
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    suffixIcon: _isEditing
                        ? const Icon(Icons.calendar_today)
                        : null,
                  ),
                  readOnly: true, // El teclado no sale, solo el picker
                  onTap: () async {
                    if (!_isEditing)
                      return; // Solo funciona si estamos editando

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                        _fechaController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Botón Guardar Cambios (Pequeño y condicional)
                if (_isEditing)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green[600], // Verde para guardar
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Guardar'),
                    ),
                  ),

                const Divider(height: 40),

                // --- SECCIÓN: GESTIONAR EQUIPO ---
                const Text(
                  'Gestionar Equipo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Text(
                  'Miembros Actuales (${_currentMiembros.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVisualizarMiembrosList(),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAgregarEstudianteDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Agregar Estudiante',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showEliminarEstudianteDialog,
                    icon: const Icon(Icons.person_remove, color: Colors.white),
                    label: const Text(
                      'Eliminar Estudiante',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                    ),
                  ),
                ),

                const Divider(height: 40),

                // --- SECCIÓN: GESTIONAR MATERIALES ---
                const Text(
                  'Gestionar Materiales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Text(
                  'Materiales Asignados (${_currentMateriales.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVisualizarMaterialesList(),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAgregarMaterialDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                    ),
                    icon: const Icon(
                      Icons.add_box_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Agregar Material',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showEliminarMaterialDialog,
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text(
                      'Eliminar Material',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                    ),
                  ),
                ),
                const Divider(height: 40),

                // --- SECCIÓN: TAREAS ---
                const Text(
                  'Gestionar Hitos y Tareas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HitosScreen(
                            projectId: widget.projectId,
                            projectName: widget.projectData['nombre'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.flag_circle_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Gestionar Hitos',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
