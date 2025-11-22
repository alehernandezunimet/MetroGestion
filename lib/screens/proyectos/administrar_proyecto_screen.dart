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

  // Variable para controlar SOLO la edición de la descripción
  bool _isEditingDescription = false;

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

  // --- Guardar cambios de Descripción ---
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
        const SnackBar(content: Text('Información actualizada con éxito.')),
      );

      setState(() {
        _isEditingDescription = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Agregar estudiante ---
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
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
                            if (mounted) Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
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
            backgroundColor: Colors.orange,
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
            backgroundColor: Colors.orange,
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
        const SnackBar(
          content: Text('Estudiante agregado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Confirmación Eliminar ---
  Future<void> _showDeleteConfirmationDialog(
    String studentId,
    String studentName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Eliminar a $studentName del proyecto?'),
                const SizedBox(height: 10),
                const Text(
                  'Esta acción borrará su acceso.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _removerMiembro(studentId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removerMiembro(String studentId) async {
    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'miembros': FieldValue.arrayRemove([studentId]),
      });

      setState(() {
        _currentMiembros.remove(studentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estudiante eliminado.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Lista de Miembros (Siempre visible los controles) ---
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
          return const Text('Error al cargar datos.');
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        miembro['nombre'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      miembro['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      miembro['email'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar miembro',
                      onPressed: () => _showDeleteConfirmationDialog(
                        miembro['uid'],
                        miembro['nombre'],
                      ),
                    ),
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
                trailing: Text('Cant: ${material['cantidad'] ?? 0}'),
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
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (int.tryParse(value) == null || int.parse(value) <= 0)
                      return 'Inválido';
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
      setState(() => _currentMateriales.add(material));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material agregado.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    if (_currentMateriales.isEmpty) return const Text('No hay materiales.');

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
    if (miembrosIds.isEmpty) return [];

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

  Future<void> _removerMaterial(Map<String, dynamic> material) async {
    try {
      await _firestore.collection('proyectos').doc(widget.projectId).update({
        'materiales': FieldValue.arrayRemove([material]),
      });
      setState(() => _currentMateriales.remove(material));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material eliminado.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                // --- DASHBOARD ---
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
                        ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (hitosSnapshot.hasError)
                      return const Text('Error en dashboard.');

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
                              name: data['nombre'] ?? 'Tarea',
                              isCompleted: data['estado'] == 'completada',
                            );
                          }).toList();
                          return Hito(
                            id: hitoDoc.id,
                            name: hitoDoc.data()['nombre'] ?? 'Hito',
                            tasks: tasks,
                          );
                        }).toList(),
                      ),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState ==
                            ConnectionState.waiting)
                          return const CircularProgressIndicator();
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

                // --- INFORMACIÓN GENERAL (Con Modo Edición) ---
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
                    if (!_isEditingDescription)
                      IconButton(
                        onPressed: () =>
                            setState(() => _isEditingDescription = true),
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

                TextFormField(
                  controller: _descripcionController,
                  enabled: _isEditingDescription,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: _isEditingDescription
                        ? const OutlineInputBorder()
                        : InputBorder.none,
                    filled: _isEditingDescription,
                    fillColor: _isEditingDescription
                        ? Colors.grey[50]
                        : Colors.transparent,
                    contentPadding: _isEditingDescription
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _fechaController,
                  enabled: _isEditingDescription,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Entrega',
                    border: _isEditingDescription
                        ? const OutlineInputBorder()
                        : InputBorder.none,
                    filled: _isEditingDescription,
                    fillColor: _isEditingDescription
                        ? Colors.grey[50]
                        : Colors.transparent,
                    contentPadding: _isEditingDescription
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    suffixIcon: _isEditingDescription
                        ? const Icon(Icons.calendar_today)
                        : null,
                  ),
                  readOnly: true,
                  onTap: () async {
                    if (!_isEditingDescription) return;
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
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

                if (_isEditingDescription)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Guardar'),
                    ),
                  ),

                const Divider(height: 40),

                // --- GESTIONAR EQUIPO (Siempre Visible) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestionar Equipo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _showAgregarEstudianteDialog,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      tooltip: 'Agregar Estudiante',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVisualizarMiembrosList(),

                const Divider(height: 40),

                // --- GESTIONAR MATERIALES ---
                const Text(
                  'Gestionar Materiales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildVisualizarMaterialesList(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAgregarMaterialDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Agregar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showEliminarMaterialDialog,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),

                // --- SECCIÓN: ACTIVIDADES (MODIFICADO) ---
                // Ahora es una fila limpia con título y botón pequeño
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Actividades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
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
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Gestionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
